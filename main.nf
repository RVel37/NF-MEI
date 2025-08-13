nextflow.enable.dsl = 2

/* Parameters located in nextflow.config */

/* MODULE IMPORTS */
include {SCRAMBLE} from './tasks/scramble.nf'
include {MELT} from './tasks/melt.nf'
include {MOBSTER} from './tasks/mobster.nf'
include {MOBTOVCF} from './tasks/mobtovcf.nf'
include {DEEPMEI} from './tasks/deepmei.nf'

workflow {

    // Pair each bam with corresponding bai
    bam_pairs = Channel
            .from(params.bams)
            .map { pair -> tuple(file(pair[0]), file(pair[1])) }

    ref_ch = Channel
        .from(params.refs)       // emit each file
        .map { file(it) }        // treat each string as a file
        .collect()               // gather into single list

    // PROCESSES
    if(params.tools.contains('scramble'))
        SCRAMBLE(bam_pairs, ref_ch)
    
    if(params.tools.contains('melt'))
        MELT(bam_pairs, ref_ch)

    if (params.tools.contains('mobster')) {
        mob_txt_ch = MOBSTER(bam_pairs, ref_ch)
    
        MOBTOVCF(mob_txt_ch)
    }

    if (params.tools.contains('deepmei'))
        DEEPMEI(bam_pairs, ref_ch)

}