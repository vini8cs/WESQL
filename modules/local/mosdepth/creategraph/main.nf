process MOSDEPTH_CREATEGRAPH {
    tag "${meta.id}"
    debug params.debug
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mosdepth:0.3.10--h4e814b3_1' :
        'biocontainers/mosdepth:0.3.10--h4e814b3_1'}"

    input:
        tuple val(meta), path(global_txt)
    output:
        tuple val(meta), path("dist.html")

    script:
    """
    python plot-dist.py ${global_txt}
    """
    stub:
    """
    touch dist.html
    """
}