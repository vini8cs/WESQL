process MD5SUM_CHECKHASH {
    tag "${meta.id}"
    debug params.debug
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'quay.io/nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(md5sum_file), val(base_md5sum)
    output:
    stdout

    script:
    """
    extracted_md5=\$(cut -d ' ' -f 1 ${md5sum_file})

    if [[ "\$extracted_md5" == "${base_md5sum}" ]]; then
        echo true
    else
        echo false
    fi
    """
    stub:
    """
    echo true
    """
}
