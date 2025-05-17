process KRAKEN2_CONTAMINATION {
    tag "$meta.id"
    label 'process_low'

    container "docker.io/vini8cs/polars_matplotlib:1.0"

    input:
    tuple val(meta), path(kraken_report)

    output:
    tuple val(meta), path("*.pdf"), emit: pdf
    tuple val(meta), stdout, emit: contamination_estimation

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    create_contamination_plot.py -r ${kraken_report}
    """
    stub:
    """
    touch contamination_graph.pdf
    """
}
