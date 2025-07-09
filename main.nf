nextflow.enable.dsl = 2

/* PARAMETERS */

params.bam_dir   = "${baseDir}/bams/scramblebam"      // directory with .bam & .bai
params.ref_dir   = "${baseDir}/reference/scrambleref"      // directory with reference genome
params.truth_vcf = "${baseDir}/truth/test.vcf" // truth VCF
params.outdir    = "${baseDir}/results"        // destination root
params.tools     = ['scramble','melt','mobster']          // names of MEI tools to run

/* MODULE IMPORTS */
include {SCRAMBLE} from './tasks/scramble.nf'
include {MELT} from './tasks/melt.nf'
include {MOBSTER} from './tasks/mobster.nf'

workflow {

    // Pair each bam with corresponding bai
    Channel
        .fromPath("${params.bam_dir}/*.bam")                // emit every bam in folder
        .map { bam -> tuple(bam, file("${bam}.bai")) }      // match bam to bai
        .set { bam_pairs }

    ref_ch = Channel.fromPath("${params.ref_dir}/*").collect()
    
    // truth vcf channel
    Channel
        .value(file(params.truth_vcf))
        .set { truth_vcf_ch }


    // PROCESSES
    if(params.tools.contains('scramble'))
        SCRAMBLE(bam_pairs, ref_ch)
    
    if(params.tools.contains('melt'))
        MELT(bam_pairs, ref_ch)

    if (params.tools.contains('mobster'))
        MOBSTER(bam_pairs, ref_ch)

}