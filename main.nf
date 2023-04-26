#!/usr/bin/env nextflow

// Example of an bacterial analysis pipeline
nextflow.enable.dsl=2

include { samtools_sort as samtools_sort_ref        } from './nextflow-modules/modules/samtools/main.nf'
include { samtools_sort as samtools_sort_assembly   } from './nextflow-modules/modules/samtools/main.nf'
include { samtools_index as samtools_index_ref      } from './nextflow-modules/modules/samtools/main.nf'
include { samtools_index as samtools_index_assembly } from './nextflow-modules/modules/samtools/main.nf'
include { sambamba_markdup                          } from './nextflow-modules/modules/sambamba/main.nf'
include { freebayes                                 } from './nextflow-modules/modules/freebayes/main.nf'
include { assembly_trim_clean                       } from './nextflow-modules/modules/clean/main.nf'
include { spades_iontorrent                         } from './nextflow-modules/modules/spades/main.nf'
include { spades_illumina                           } from './nextflow-modules/modules/spades/main.nf'
include { skesa                                     } from './nextflow-modules/modules/skesa/main.nf'
include { save_analysis_metadata                    } from './nextflow-modules/modules/meta/main.nf'
include { mask_polymorph_assembly                   } from './nextflow-modules/modules/mask/main.nf'
include { export_to_cdm                             } from './nextflow-modules/modules/cmd/main.nf'
include { quast                                     } from './nextflow-modules/modules/quast/main.nf'
include { mlst                                      } from './nextflow-modules/modules/mlst/main.nf'
include { ariba_prepareref                          } from './nextflow-modules/modules/ariba/main.nf'
include { ariba_run                                 } from './nextflow-modules/modules/ariba/main.nf'
include { ariba_summary                             } from './nextflow-modules/modules/ariba/main.nf'
include { ariba_summary_to_json                     } from './nextflow-modules/modules/ariba/main.nf'
include { kraken                                    } from './nextflow-modules/modules/kraken/main.nf'
include { bracken                                   } from './nextflow-modules/modules/bracken/main.nf'
include { bwa_mem as bwa_mem_ref                    } from './nextflow-modules/modules/bwa/main.nf'
include { bwa_mem as bwa_mem_dedup                  } from './nextflow-modules/modules/bwa/main.nf'
include { bwa_index                                 } from './nextflow-modules/modules/bwa/main.nf'
include { post_align_qc                             } from './nextflow-modules/modules/qc/main.nf'
include { chewbbaca_allelecall                      } from './nextflow-modules/modules/chewbbaca/main.nf'
include { chewbbaca_split_results                   } from './nextflow-modules/modules/chewbbaca/main.nf'
include { chewbbaca_create_batch_list               } from './nextflow-modules/modules/chewbbaca/main.nf'
include { resfinder                                 } from './nextflow-modules/modules/resfinder/main.nf'
include { virulencefinder                           } from './nextflow-modules/modules/virulencefinder/main.nf'
include { create_analysis_result                    } from './nextflow-modules/modules/prp/main.nf'

// Function for platform and paired-end or single-end
def get_meta(LinkedHashMap row) {
  platforms = ["illumina", "nanopore", "pacbio", "iontorrent"]
  if (row.platform in platforms) {
    if (row.read2) {
      meta = tuple(row.id, tuple(file(row.read1), file(row.read2)), row.platform)
    } else {
      meta = tuple(row.id, tuple(file(row.read1)), row.platform)
    }
  } else {
    exit 1, "ERROR: Please check input samplesheet -> Platform is not one of the following:!\n-${platforms.join('\n-')}"
  }
  return meta
}

workflow bacterial_default {
  Channel.fromPath(params.csv).splitCsv(header:true)
    .map{ row -> get_meta(row) }
    .branch {
      iontorrent: it[2] == "iontorrent"
      illumina: it[2] == "illumina"
    }
    .set{ meta }

  // load references 
  genomeReference = file(params.genomeReference, checkIfExists: true)
  genomeReferenceDir = file(genomeReference.getParent(), checkIfExists: true)
  // databases
  mlstDb = file(params.mlstBlastDb, checkIfExists: true)
  cgmlstDb = file(params.cgmlstDb, checkIfExists: true)
  cgmlstLociBed = file(params.cgmlstLociBed, checkIfExists: true)
  trainingFile = file(params.trainingFile, checkIfExists: true)
  resfinderDb = file(params.resfinderDb, checkIfExists: true)
  pointfinderDb = file(params.pointfinderDb, checkIfExists: true)
  virulencefinderDb = file(params.virulencefinderDb, checkIfExists: true)

  main:
    // reads trim and clean
    assembly_trim_clean(meta.iontorrent).set{ clean_meta }
    meta.illumina.mix(clean_meta).set{ input_meta }
    input_meta.map { sampleName, reads, platform -> [ sampleName, reads ] }.set{ reads }

    // analysis metadata
    save_analysis_metadata(input_meta)

    // assembly and qc processing
    bwa_mem_ref(reads, genomeReferenceDir)
    samtools_sort_ref(bwa_mem_ref.out.sam, [])
    samtools_index_ref(samtools_sort_ref.out.bam)

    //sambamba_markdup(samtools_sort_ref.out.bam, samtools_index_ref.out.bai)
    samtools_sort_ref.out.bam
      .join(samtools_index_ref.out.bai)
      .multiMap { id, bam, bai -> 
        bam: tuple(id, bam)
        bai: bai
      }
      .set{ post_align_qc_ch }
    post_align_qc(post_align_qc_ch.bam, post_align_qc_ch.bai, cgmlstLociBed)
    
    // assembly
    skesa(input_meta)
    spades_illumina(input_meta)
    spades_iontorrent(input_meta)

    Channel.empty().mix(skesa.out.fasta, spades_illumina.out.fasta, spades_iontorrent.out.fasta).set{ assembly }

    // mask polymorph regions
    bwa_index(assembly)
    reads
      .join(bwa_index.out.idx)
      .multiMap { id, reads, bai -> 
        reads: tuple(id, reads)
        bai: bai
      }
      .set { bwa_mem_dedup_ch }
    bwa_mem_dedup(bwa_mem_dedup_ch.reads, bwa_mem_dedup_ch.bai)
    samtools_sort_assembly(bwa_mem_dedup.out.sam, [])
    samtools_index_assembly(samtools_sort_assembly.out.bam)
    // construct freebayes input channels
    assembly
      .join(samtools_sort_assembly.out.bam)
      .join(samtools_index_assembly.out.bai)
      .multiMap { id, fasta, bam, bai -> 
        assembly: tuple(id, fasta)
        mapping: tuple(bam, bai)
      }
      .set { freebayes_ch }

    freebayes(freebayes_ch.assembly, freebayes_ch.mapping)
    mask_polymorph_assembly(assembly.join(freebayes.out.vcf))
    quast(assembly, genomeReference)
    mlst(assembly, params.species, mlstDb)
    // split assemblies and id into two seperate channels to enable re-pairing
    // of results and id at a later stage. This to allow batch cgmlst analysis 
    mask_polymorph_assembly.out.fasta
      .multiMap { sampleName, filePath -> 
        sampleName: sampleName
        filePath: filePath
      }
      .set{ maskedAssemblyMap }

    chewbbaca_create_batch_list(maskedAssemblyMap.filePath.collect())
    chewbbaca_allelecall(maskedAssemblyMap.sampleName.collect(), chewbbaca_create_batch_list.out.list, cgmlstDb, trainingFile)
    chewbbaca_split_results(chewbbaca_allelecall.out.sampleName, chewbbaca_allelecall.out.calls)

    // end point
    export_to_cdm(chewbbaca_split_results.out.output.join(quast.out.qc).join(post_align_qc.out.qc))

    // antimicrobial detection (amrfinderplus & abritamr)

    // perform resistance prediction
    resfinder(reads, params.species, resfinderDb, pointfinderDb)
    virulencefinder(reads, params.useVirulenceDbs, virulencefinderDb)

    // combine results for export
    quast.out.qc
      .join(mlst.out.json)
      .join(chewbbaca_split_results.out.output)
      .join(resfinder.out.json)
      .join(resfinder.out.meta)
      .join(virulencefinder.out.json)
      .join(virulencefinder.out.meta)
      .set{ combinedOutput }

    // Using kraken for species identificaiton
    if ( params.useKraken ) {
      krakenDb = file(params.krakenDb, checkIfExists: true)
      kraken(reads, krakenDb)
      bracken(kraken.out.report, krakenDb).output
      combinedOutput = combinedOutput.join(bracken.out.output)
      create_analysis_result(
        save_analysis_metadata.out.meta, 
        combinedOutput
      )
	  } else {
      emptyBrackenOutput = reads.map { sampleName, reads -> [ sampleName, [] ] }
      combinedOutput = combinedOutput.join(emptyBrackenOutput)
      create_analysis_result(
        save_analysis_metadata.out.meta, 
        combinedOutput
      )
	  }
    
  emit: 
    pipeline_result = create_analysis_result.output
    cdm_import = export_to_cdm.output
}
