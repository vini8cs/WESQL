process SAMTOOLS_INFERGENETICSEX {
    tag "$meta.id"
    label 'process_low'

    container "docker.io/vini8cs/polars_matplotlib:1.0"

    input:
    tuple val(meta), path(depth_tsv_file)

    output:
    tuple val(meta), path("*.txt"), emit: txt

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    genetic_sex_infer.py -f ${depth_tsv_file}
    """
    stub:
    """
    touch sex_infer.txt
    """
}
