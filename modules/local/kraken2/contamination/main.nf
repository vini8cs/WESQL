process KRAKEN2_CONTAMINATION {
    tag "$meta.id"
    label 'process_low'

    container "docker.io/vini8cs/polars_matplotlib:1.0"

    input:
    tuple val(meta), path(kraken_report)

    output:
    tuple val(meta), path("*.pdf"), emit: pdf
    tuple val(meta), path("*.txt"), emit: contamination_estimation

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    create_contamination_plot.py -r ${kraken_report} -g ${prefix}.pdf -e ${prefix}.txt
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.{pdf,txt}
    """
}
