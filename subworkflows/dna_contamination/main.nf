include { KRAKEN2_KRAKEN2 } from '../../modules/nf-core/kraken2/kraken2/main'
include { KRAKEN2_CONTAMINATION } from '../../modules/local/kraken2/contamination/main'
include { SAMTOOLS_FASTQ } from '../../modules/nf-core/samtools/fastq/main'

workflow DNA_CONTAMINATION {
    take:
        cram_ch

    main:
        fastq_files_ch = SAMTOOLS_FASTQ(
            cram_ch.map{ meta, cram, _crai -> tuple(meta, cram)},
            Channel.value(false)
        )

        kraken_report_ch = KRAKEN2_KRAKEN2(
            fastq_files_ch.fastq,
            params.KRAKEN_DB,
            Channel.value(false),
            Channel.value(false)
        )

        contamination_ch = KRAKEN2_CONTAMINATION(kraken_report_ch.report)
    emit:
        contamination_plot       = contamination_ch.pdf
        contamination_estimation = contamination_ch.contamination_estimation
}
