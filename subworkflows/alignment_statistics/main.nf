include { SAMTOOLS_FLAGSTAT } from '../../modules/nf-core/samtools/flagstat/main'
include { SAMTOOLS_IDXSTATS } from '../../modules/nf-core/samtools/idxstats/main'

def removeItemFromMeta(meta, item) {
    def new_meta = meta.clone()
    new_meta.remove(item)
    return new_meta
}

workflow ALIGNMENT_STATISTICS {
    take:
        cram_file_ch
        cram_index_ch

    main:
        cram_ch = cram_file_ch.map { meta, file, _md5 ->
            def new_meta = removeItemFromMeta(meta, "file")
            tuple(new_meta, file)
        }.combine(
            cram_index_ch.map { meta, file, _md5 ->
                def new_meta = removeItemFromMeta(meta, "file")
                tuple(new_meta, file)
            }, by: 0
        )

        alignment_statistics_ch = SAMTOOLS_FLAGSTAT(cram_ch).flagstat
        SAMTOOLS_IDXSTATS(cram_ch)

    emit:
        alignment_statistics_ch
        cram_ch
    
}
