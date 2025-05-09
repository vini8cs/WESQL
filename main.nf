include { MD5SUM } from './modules/nf-core/md5sum/main'

workflow {
    samples_ch = Channel.fromList(params.samples).map {
        sample -> tuple([id: sample.sample_id], [sample.cram_file, sample.cram_index, sample.bed_file])
    }

    MD5SUM(samples_ch, Channel.value(true))
}