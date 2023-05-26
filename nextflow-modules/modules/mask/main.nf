process mask_polymorph_assembly {
  tag "${sampleName}"
  scratch params.scratch

  input:
    tuple val(sampleName), path(assembly), path(polymorph)

  output:
    tuple val(sampleName), path(output), emit: fasta

  script:
    output = "${sampleName}.fasta"
    """
    error_corr_assembly.pl ${assembly} ${polymorph} > ${output}
    """

  stub:
    output = "${sampleName}.fasta"
    """
    touch $output
    """
}