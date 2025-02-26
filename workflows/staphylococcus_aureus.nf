#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { get_meta                                  } from '../methods/get_meta'
include { amrfinderplus                             } from '../nextflow-modules/modules/amrfinderplus/main'
include { bracken                                   } from '../nextflow-modules/modules/bracken/main'
include { bwa_index                                 } from '../nextflow-modules/modules/bwa/main'
include { bwa_mem as bwa_mem_dedup                  } from '../nextflow-modules/modules/bwa/main'
include { chewbbaca_allelecall                      } from '../nextflow-modules/modules/chewbbaca/main'
include { chewbbaca_create_batch_list               } from '../nextflow-modules/modules/chewbbaca/main'
include { chewbbaca_split_results                   } from '../nextflow-modules/modules/chewbbaca/main'
include { create_analysis_result                    } from '../nextflow-modules/modules/prp/main'
include { export_to_cdm                             } from '../nextflow-modules/modules/cmd/main'
include { freebayes                                 } from '../nextflow-modules/modules/freebayes/main'
include { kraken                                    } from '../nextflow-modules/modules/kraken/main'
include { mask_polymorph_assembly                   } from '../nextflow-modules/modules/mask/main'
include { mlst                                      } from '../nextflow-modules/modules/mlst/main'
include { resfinder                                 } from '../nextflow-modules/modules/resfinder/main'
include { samtools_index as samtools_index_assembly } from '../nextflow-modules/modules/samtools/main'
include { virulencefinder                           } from '../nextflow-modules/modules/virulencefinder/main'
include { CALL_BACTERIAL_BASE                       } from '../workflows/bacterial_base.nf'

workflow CALL_STAPHYLOCOCCUS_AUREUS {
    Channel.fromPath(params.csv).splitCsv(header:true)
        .map{ row -> get_meta(row) }
        .branch {
        iontorrent: it[2] == "iontorrent"
        illumina: it[2] == "illumina"
        }
        .set{ ch_meta }

    // load references 
    genomeReference = file(params.genomeReference, checkIfExists: true)
    genomeReferenceDir = file(genomeReference.getParent(), checkIfExists: true)
    // databases
    amrfinderDb = file(params.amrfinderDb, checkIfExists: true)
    mlstDb = file(params.mlstBlastDb, checkIfExists: true)
    chewbbacaDb = file(params.chewbbacaDb, checkIfExists: true)
    coreLociBed = file(params.coreLociBed, checkIfExists: true)
    trainingFile = file(params.trainingFile, checkIfExists: true)
    resfinderDb = file(params.resfinderDb, checkIfExists: true)
    pointfinderDb = file(params.pointfinderDb, checkIfExists: true)
    virulencefinderDb = file(params.virulencefinderDb, checkIfExists: true)

    main:
        ch_versions = Channel.empty()

        CALL_BACTERIAL_BASE( coreLociBed, genomeReference, genomeReferenceDir, ch_meta.iontorrent, ch_meta.illumina )
        
        CALL_BACTERIAL_BASE.out.assembly.set{ch_assembly}
        CALL_BACTERIAL_BASE.out.reads.set{ch_reads}
        CALL_BACTERIAL_BASE.out.quast.set{ch_quast}
        CALL_BACTERIAL_BASE.out.quast.set{ch_quast}
        CALL_BACTERIAL_BASE.out.qc.set{ch_qc}
        CALL_BACTERIAL_BASE.out.metadata.set{ch_metadata}

        bwa_index(ch_assembly)

        ch_reads
            .join(bwa_index.out.idx)
            .multiMap { id, reads, bai -> 
                reads: tuple(id, reads)
                bai: bai
            }
            .set { bwa_mem_dedup_ch }
        bwa_mem_dedup(bwa_mem_dedup_ch.reads, bwa_mem_dedup_ch.bai)
        samtools_index_assembly(bwa_mem_dedup.out.bam)

        // construct freebayes input channels
        ch_assembly
            .join(bwa_mem_dedup.out.bam)
            .join(samtools_index_assembly.out.bai)
            .multiMap { id, fasta, bam, bai -> 
                assembly: tuple(id, fasta)
                mapping: tuple(bam, bai)
            }
            .set { freebayes_ch }

        // VARIANT CALLING
        freebayes(freebayes_ch.assembly, freebayes_ch.mapping)

        mask_polymorph_assembly(ch_assembly.join(freebayes.out.vcf))

        // TYPING
        mlst(ch_assembly, params.species, mlstDb)

        mask_polymorph_assembly.out.fasta
            .multiMap { sampleName, filePath -> 
                sampleName: sampleName
                filePath: filePath
            }
            .set{ maskedAssemblyMap }

        chewbbaca_create_batch_list(maskedAssemblyMap.filePath.collect())
        chewbbaca_allelecall(maskedAssemblyMap.sampleName.collect(), chewbbaca_create_batch_list.out.list, chewbbacaDb, trainingFile)
        chewbbaca_split_results(chewbbaca_allelecall.out.sampleName, chewbbaca_allelecall.out.calls)

        // SCREENING
        // antimicrobial detection (amrfinderplus)
        amrfinderplus(ch_assembly, amrfinderDb)

        // resistance & virulence prediction
        resfinder(ch_reads, params.species, resfinderDb, pointfinderDb)
        virulencefinder(ch_reads, params.useVirulenceDbs, virulencefinderDb)

        export_to_cdm(chewbbaca_split_results.out.output.join(ch_quast).join(ch_qc))

        ch_reads.map { sampleName, reads -> [ sampleName, [] ] }.set{ ch_empty }

        ch_quast
            .join(ch_qc)
            .join(mlst.out.json)
            .join(chewbbaca_split_results.out.output)
            .join(amrfinderplus.out.output)
            .join(resfinder.out.json)
            .join(resfinder.out.meta)
            .join(virulencefinder.out.json)
            .join(virulencefinder.out.meta)
            .join(ch_metadata)
            .join(ch_empty)
            .join(ch_empty)
            .join(ch_empty)
            .set{ combinedOutput }

        if ( params.useKraken ) {
            krakenDb = file(params.krakenDb, checkIfExists: true)
            kraken(ch_reads, krakenDb)
            bracken(kraken.out.report, krakenDb).output
            combinedOutput = combinedOutput.join(bracken.out.output)
            create_analysis_result(combinedOutput)
            ch_versions = ch_versions.mix(kraken.out.versions)
            ch_versions = ch_versions.mix(bracken.out.versions)
        } else {
            emptyBrackenOutput = reads.map { sampleName, reads -> [ sampleName, [] ] }
            combinedOutput = combinedOutput.join(emptyBrackenOutput)
            create_analysis_result(combinedOutput)
        }

        ch_versions = ch_versions.mix(amrfinderplus.out.versions)
        ch_versions = ch_versions.mix(bwa_index.out.versions)
        ch_versions = ch_versions.mix(bwa_mem_dedup.out.versions)
        ch_versions = ch_versions.mix(chewbbaca_allelecall.out.versions)
        ch_versions = ch_versions.mix(freebayes.out.versions)
        ch_versions = ch_versions.mix(mlst.out.versions)
        ch_versions = ch_versions.mix(resfinder.out.versions)
        ch_versions = ch_versions.mix(samtools_index_assembly.out.versions)
        ch_versions = ch_versions.mix(virulencefinder.out.versions)

    emit: 
        pipeline_result = create_analysis_result.output
        cdm             = export_to_cdm.output
        versions        = ch_versions
}