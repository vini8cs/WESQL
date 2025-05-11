include { MD5SUM } from './modules/nf-core/md5sum/main'
include { MD5SUM_CHECKHASH } from './modules/local/md5sum/checkhash/main'
include { SAMTOOLS_FLAGSTAT } from './modules/nf-core/samtools/flagstat/main'
include { SAMTOOLS_STATS } from './modules/nf-core/samtools/stats/main'
include { MOSDEPTH } from './modules/nf-core/mosdepth/main'
include { MOSDEPTH_CREATEGRAPH } from './modules/local/mosdepth/creategraph/main'

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

    bed_file_ch = Channel.fromList(params.samples).map { sample ->
        tuple([id: sample.sample_id, file: "bed_file"], sample.bed_file.path, sample.bed_file.md5)
    }

    samples_ch = cram_file_ch
        .concat(cram_index_ch)
        .concat(bed_file_ch)
    
    human_genome_ch = Channel.fromPath(params.human_genome).map { file ->
        tuple([id: "human_genome"], file)
    }
    
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
    SAMTOOLS_STATS(cram_ch, [[],[]])
    SAMTOOLS_STATS.out.stats.view()

    // Coverage

    mosdepth_ch = cram_ch.combine(
        bed_file_ch.map { meta, file, _md5 ->
            def new_meta = remove_item_from_meta(meta, "file")
            tuple(new_meta, file)
        }, by: 0
    )

    coverage_results_ch = MOSDEPTH(
        mosdepth_ch,
        human_genome_ch
    )

    MOSDEPTH_CREATEGRAPH(coverage_results_ch.global_txt)
}
