// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

// Unfortunately, BLAT is one of those tools that does not output its version information nicely.
// To spare some very hacky string parsing, instead it is defined here exactly.
def VERSION = '36'

params.options = [:]
options        = initOptions(params.options)

process BLAT_ALIGN_TRANSCRIPTS {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::blat=36" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/blat:36--0"
    } else {
        container "quay.io/biocontainers/blat:36--0"
    }

    input:
    tuple val(meta), path(db)
    path(query)

    output:
    tuple val(meta), path("*.bam"), emit: psl
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"

    """
    blat \\
        $options.args \\
        $genome \\
        $query \\
        ${prefix}.psl

    echo $VERSION > ${software}.version.txt
    """
}
