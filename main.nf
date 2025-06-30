nextflow.enable.dsl = 2

/* PARAMETERS */

params.bam_dir   = "${baseDir}/bams"      // directory with .bam & .bai
params.ref_dir   = "${baseDir}/reference"      // directory with reference genome
params.truth_vcf = "${baseDir}/truth/benchmark.vcf.gz" // ground‑truth VCF
params.outdir    = "${baseDir}/results"        // destination root
params.tools     = ['scramble']          // names of MEI tools to run

/* CHANNELS */

include {SCRAMBLE} from './tasks/scramble.nf'

workflow {

    // Pair each bam with its bai
    Channel
        .fromPath("${params.bam_dir}/*.bam")
        .map { bam -> tuple(bam, file("${bam}.bai")) }
        .set { bam_pairs }

    // also attach ref + truthset
    bam_pairs
        .map { bam, bai -> tuple(bam, bai, file(params.ref_dir), file(params.truth_vcf)) }
        .set { sample_input }


    // PROCESSES
    if(params.tools.contains('scramble'))
        SCRAMBLE(sample_input)


}