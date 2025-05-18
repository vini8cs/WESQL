include { MD5SUM } from '../../modules/nf-core/md5sum/main'
include { MD5SUM_CHECKHASH } from '../../modules/local/md5sum/checkhash/main'

workflow MD5_CHECK_PROCESS {
    take:
        samples_ch
    main:
     
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
