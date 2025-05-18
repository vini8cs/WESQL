include { SAMTOOLS_CREATECOVERAGEGRAPH } from '../../modules/local/samtools/createcoveragegraph/main'
include { SAMTOOLS_INFERGENETICSEX } from '../../modules/local/samtools/infergeneticsex/main'
include { SAMTOOLS_DEPTH } from '../../modules/local/samtools/depth/main' 

workflow GENOME_COVERAGE{
    take:
        cram_ch
        bed_file_ch
    main:
        coverage_ch = SAMTOOLS_DEPTH(
            cram_ch.map{ meta, cram, _crai -> tuple(meta, cram)},
            bed_file_ch.map{ meta, bed_file, _md5 -> tuple(meta, bed_file)}.collect()
        )

        sex_inference_ch = SAMTOOLS_INFERGENETICSEX(coverage_ch.tsv).txt

        coverage_files_ch = coverage_ch.tsv.map {_meta, file ->
            def new_meta = [id: "coverage"]
            tuple(new_meta, file)
        }.groupTuple()

        coverage_plots_ch = SAMTOOLS_CREATECOVERAGEGRAPH(
            coverage_files_ch
        )
    emit:
        coverage_plots = coverage_plots_ch.pdf
        sex_inference  = sex_inference_ch
}
