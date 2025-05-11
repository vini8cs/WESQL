process MOSDEPTH_CREATEGRAPH {
    tag "${meta.id}"
    debug params.debug
    container "docker.io/vini8cs/mosdepth_graph:1.0"

    input:
        tuple val(meta), path(global_txt)
    output:
        tuple val(meta), path("dist.html")

    script:
    """
    python /mosdepth/scripts/plot-dist.py ${global_txt}
    """
    stub:
    """
    touch dist.html
    """
}
