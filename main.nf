include { MD5SUM } from './modules/nf-core/md5sum/main'
include { MD5SUM_CHECKHASH } from './modules/local/md5sum/checkhash/main'
include { SAMTOOLS_FLAGSTAT } from './modules/nf-core/samtools/flagstat/main'
include { SAMTOOLS_DEPTH } from './modules/local/samtools/depth/main' 
include { MOSDEPTH_CREATEGRAPH } from './modules/local/mosdepth/creategraph/main'
include { SAMTOOLS_IDXSTATS } from './modules/nf-core/samtools/idxstats/main'
include { SAMTOOLS_CREATECOVERAGEGRAPH } from './modules/local/samtools/createcoveragegraph/main'
include { SAMTOOLS_INFERGENETICSEX } from './modules/local/samtools/infergeneticsex/main'
include { SAMTOOLS_FASTQ } from './modules/nf-core/samtools/fastq/main'
include { KRAKEN2_KRAKEN2 } from './modules/nf-core/kraken2/kraken2/main'

def remove_item_from_meta(meta, item) {
    def new_meta = meta.clone()
    new_meta.remove(item)
    return new_meta
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
    
    // Checksum files
    
    md5sum_check_value_ch = MD5SUM(
        samples_ch.map{meta, file, _md5 -> 
            tuple(meta, file)
        }, 
        Channel.value(false)
    )

    all_files_valid = MD5SUM_CHECKHASH(
        md5sum_check_value_ch.checksum
            .combine(
                samples_ch.map{meta, _file, md5 ->
                    tuple(meta, md5)}, by: 0
            )
    )
    
    all_files_valid.collect().subscribe { results ->
        def bool_results = results.collect { it.toString().trim() == 'true' }
        if (bool_results.every { it }) {
            log.info("All files passed the MD5 checksum validation.")
        } else {
            log.error("Some files failed the MD5 checksum validation.")
            error("Workflow stopped due to invalid files.")
        }
    }

    // Alignment Statistics

    cram_ch = cram_file_ch.map { meta, file, _md5 ->
        def new_meta = remove_item_from_meta(meta, "file")
        tuple(new_meta, file)
    }.combine(
        cram_index_ch.map { meta, file, _md5 ->
            def new_meta = remove_item_from_meta(meta, "file")
            tuple(new_meta, file)
        }, by: 0
    )

    SAMTOOLS_FLAGSTAT(cram_ch)
    SAMTOOLS_IDXSTATS(cram_ch)

    // Coverage
    
    coverage_ch = SAMTOOLS_DEPTH(
        cram_ch.map{ meta, cram, _crai -> tuple(meta, cram)},
        bed_file_ch.map{ meta, bed_file, _md5 -> tuple(meta, bed_file)}.collect()
    )

    SAMTOOLS_INFERGENETICSEX(coverage_ch.tsv)

    coverage_files_ch = coverage_ch.tsv.map {_meta, file ->
        def new_meta = [id: "coverage"]
        tuple(new_meta, file)
    }.groupTuple()

    SAMTOOLS_CREATECOVERAGEGRAPH(
       coverage_files_ch
    )

    // DNA Contamination

    fastq_files_ch = SAMTOOLS_FASTQ(
        cram_ch.map{ meta, cram, _crai -> tuple(meta, cram)},
        Channel.value(false)
    )

    KRAKEN2_KRAKEN2(
        fastq_files_ch.fastq,
        params.KRAKEN_DB,
        Channel.value(false),
        Channel.value(false)
    )

    
}
