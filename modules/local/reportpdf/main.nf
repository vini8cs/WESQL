process REPORTPDF {
    tag "reportpdf"
    debug params.debug
    container "docker.io/vini8cs/pandoc-texlive:1.0"
    
    input:
    tuple val(meta1), path(alignment_statistics)
    tuple val(meta2), path(sex_inference)
    tuple val(meta3), path(coverage_plots)
    tuple val(meta4), path(contamination_plots)
    tuple val(meta5), path (contamination_estimation)

    output:
    path("report.pdf"), emit: pdf
    path("report.md"), emit: md

    script:
    """
    create_pdf_report.py \
        --author "${params.author}" \
        --date ${params.trace_timestamp} \
        --alignment_statistics_files ${alignment_statistics} \
        --sex_inference_files ${sex_inference} \
        --coverage_plots ${coverage_plots} \
        --contamination_estimation ${contamination_estimation} \
        --contamination_plots ${contamination_plots}
    
    pandoc report.md -o report.pdf --pdf-engine=pdflatex
    """
    stub:
    """
    touch report.pdf
    touch report.md
    """
}
