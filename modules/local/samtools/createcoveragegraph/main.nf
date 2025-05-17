process SAMTOOLS_CREATECOVERAGEGRAPH {
    tag "$meta.id"
    label 'process_low'

    container "docker.io/vini8cs/polars_matplotlib:1.0"

    input:
    tuple val(meta), path(depth_tsv_file)

    output:
    tuple val(meta), path("*.pdf"), emit: pdf

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    coverage.py -f ${depth_tsv_file} -o ${prefix}.pdf
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.pdf
    """
}
