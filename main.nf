include { MD5SUM } from './modules/nf-core/md5sum/main'
include { MD5SUM_CHECKHASH } from './modules/local/md5sum/checkhash/main'

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

    
}