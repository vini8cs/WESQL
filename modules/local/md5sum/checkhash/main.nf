process MD5SUM_CHECKHASH {
    tag "${meta.id}"
    debug params.debug

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