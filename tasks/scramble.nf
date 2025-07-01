process SCRAMBLE {
    container 'swglh/scramble:1.0'

    tag "${bam.baseName}"

    publishDir "${params.outdir}/scramble", mode: 'copy'

    input:
    tuple path(bam), path(bai)
    path(ref_ch) 
    path(truth_vcf)

    output:
    file("${bam.baseName}.clusters.txt")
    file("${bam.baseName}.scramble.vcf")

    script:
    """
    # find the fasta file among the staged reference files
    fasta_file=\$(ls ${ref_ch} | grep -E '\\.fa(sta)?\$' | head -n1)

    if [[ -z "\$fasta_file" ]]; then
      echo "ERROR: fasta file not found among reference files"
      exit 1
    fi

    head -n 10 "\$fasta_file"

    ### Step 1: Run clustering on the input BAM file
    cluster_identifier $bam > ${bam.baseName}.clusters.txt

    ### Step 2: Run SCRAMble.R using the clustered reads (full paths used)
    Rscript --vanilla /scramble/cluster_analysis/bin/SCRAMble.R \\
      --out-name "\$(pwd)/${bam.baseName}" \\
      --cluster-file \$(pwd)/${bam.baseName}.clusters.txt \\
      --install-dir /scramble/cluster_analysis/bin \\
      --mei-refs /scramble/cluster_analysis/resources/MEI_consensus_seqs.fa \\
      --ref "\$fasta_file" \\
      --eval-meis

    mv ${bam.baseName}.vcf ${bam.baseName}.scramble.vcf
    """
}
