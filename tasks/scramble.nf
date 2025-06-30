
process SCRAMBLE {
    // label will pull dynamic resource logic
    //label 'mei'

    container 'swglh/scramble:1.0'

    // tag printed in logs to identify which bam is being processed
    tag "${bam.baseName}"
    
    // outputs go here
    publishDir "${params.outdir}/scramble", mode: 'copy'

    // inputs & outputs
    input:
    tuple path(bam), path(bai), path(ref_dir), path(truth_vcf)

    output:
    file("${bam.baseName}.clusters.txt")
    file("${bam.baseName}.scramble.vcf")
    // file("${bam.baseName}.metrics.txt")


    script: """

    find / -name cluster_identifier 2>/dev/null

    ### Step 1: Run clustering on the input BAM file
    cluster_identifier $bam > ${bam.baseName}.clusters.txt

    ### Step 2: Run SCRAMble.R using the clustered reads (full paths used)
    Rscript --vanilla /scramble/cluster_analysis/bin/SCRAMble.R \\
      --out-name "\$(pwd)/${bam.baseName}" \\
      --cluster-file \$(pwd)/${bam.baseName}.clusters.txt \\
      --install-dir /scramble/cluster_analysis/bin \\
      --mei-refs /scramble/cluster_analysis/resources/MEI_consensus_seqs.fa \\
      --ref /scramble/validation/test.fa \\
      --eval-dels \\
      --eval-meis

    find . -name 'test.vcf'
    echo "Current dir contents:"
    ls -l

    echo "All files recursively:"
    find . -type f

    mv ${bam.baseName}.vcf ${bam.baseName}.scramble.vcf
    """

}