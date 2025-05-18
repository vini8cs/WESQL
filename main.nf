include { MD5_CHECK_PROCESS } from './subworkflows/md5_check_process/main'
include { ALIGNMENT_STATISTICS } from './subworkflows/alignment_statistics/main'
include { GENOME_COVERAGE } from './subworkflows/genome_coverage/main'
include { DNA_CONTAMINATION } from './subworkflows/dna_contamination/main'
include { REPORTPDF } from './modules/local/reportpdf/main'

def groupFilesByID(ch, new_id) {
    return ch.map{_meta, file ->
            def new_meta = [id: new_id]
            tuple(new_meta, file)
    }.groupTuple()
}

workflow {
    cram_file_ch = Channel.fromList(params.samples).map { sample ->
        tuple([id: sample.sample_id, file: "cram_file"], sample.cram_file.path, sample.cram_file.md5)
    }

    cram_index_ch = Channel.fromList(params.samples).map { sample ->
        tuple([id: sample.sample_id, file: "cram_index"], sample.cram_index.path, sample.cram_index.md5)
    }

    bed_file_ch = Channel.from(params.bed_file).map { bed_file ->
        tuple([id: "bed_file"], bed_file.path, bed_file.md5)
    }

    samples_ch = cram_file_ch
        .concat(cram_index_ch)
        .concat(bed_file_ch)

    MD5_CHECK_PROCESS(samples_ch)

    (alignment_statistics_ch, cram_ch) =  ALIGNMENT_STATISTICS(
        cram_file_ch,
        cram_index_ch
    )

    (coverage_plots_ch, sex_inference_ch) = GENOME_COVERAGE(
        cram_ch,
        bed_file_ch
    )

    (contamination_plot_ch, contamination_estimation_ch) = DNA_CONTAMINATION(
        cram_ch
    )
    
    REPORTPDF(
        groupFilesByID(alignment_statistics_ch, "aligment_statistics"),
        groupFilesByID(sex_inference_ch, "sex_inference"),
        coverage_plots_ch,
        groupFilesByID(contamination_plot_ch, "contamination_plots"),
        groupFilesByID(contamination_estimation_ch, "contamination_estimation"),
    )
}

workflow.onComplete {
    if (workflow.success) {
        log.info "Pipeline finished successfully"
        def date = new java.util.Date().format('yyyy-MM-dd HH-mm-ss')
        
        def msg = """
        date: ${date}
        time: ${workflow.duration}
        command line: ${workflow.commandLine}
        """

        println msg

    } else {
        log.error "Pipeline finished with errors"
        def error = workflow.errorMessage.replace('"', "'")
        def msg = """
            error: ${error}
            command line: ${workflow.commandLine}
            """
        println msg
    }
}
