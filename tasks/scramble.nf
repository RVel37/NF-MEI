
process SCRAMBLE {

    // tag printed in logs to identify which bam is being processed
    tag "${bam.baseName}"
    // label pulls dynamic resource logic
    label 'mei'
    // outputs go here
    publishDir "${params.outdir}/scramble", mode: 'copy'

    container 'swglh/scramble:1.0'

    // inputs & outputs
    input:
    tuple path(bam), path(bai), path(ref_dir), path(truth_vcf)

    output:
    path "${bam.baseName}.clusters.txt", emit: clusters
    path "${bam.baseName}.vcf", emit: vcf
    path "${bam.baseName}.scramble.metrics.txt", optional: true, emit: txt


    script: """
    mkdir -p workdir

    # Step 1: Run clustering on the input BAM file

    # Save performance metrics to a file using '/usr/bin/time -v'
    /usr/bin/time -v -o ${bam.baseName}.scramble.metrics.txt \\
      cluster_identifier $bam > ${bam.baseName}.clusters.txt

    # Step 2: Run SCRAMble.R using the clustered reads
    # Full paths used because SCRAMble may have issues with relative paths
    Rscript --vanilla cluster_analysis/bin/SCRAMble.R \\
      --out-name \$(pwd)/${bam.baseName}.scramble.vcf \\
      --cluster-file \$(pwd)/${bam.baseName}.clusters.txt \\
      --install-dir cluster_analysis/bin \\
      --mei-refs cluster_analysis/resources/MEI_consensus_seqs.fa \\
      --ref $ref_dir/genome.fa \\
      --eval-dels \\
      --eval-meis
    """
    
}
