process SCRAMBLE {
    container 'swglh/scramble:1.0'

    tag "${bam.baseName}"

    publishDir "${params.outdir}/scramble", mode: 'copy'

    input:
    tuple path(bam), path(bai)
    path(ref_ch)

    output:
    file("${bam.baseName}.clusters.txt")
    file("${bam.baseName}.scramble.vcf")

    script:
    """
    # find the fasta file in the reference directory
    fasta_file=\$(ls ${ref_ch} | grep -E '\\.fa(sta)?\$' | head -n1)
    [[ -z \$fasta_file ]] && { echo 'ERROR: no fasta'; exit 1; }
    
    # absolute path - needed for bioconductor
    fasta_file=\$(readlink -f "\$fasta_file")

    find / -name cluster_identifier 2>/dev/null

    ### Step 1: Run clustering on the input BAM file
    cluster_identifier $bam > ${bam.baseName}.clusters.txt

    ### Step 2: Run SCRAMble.R using the clustered reads (full paths used)
    Rscript --vanilla /scramble/cluster_analysis/bin/SCRAMble.R \\
      --out-name "\$(pwd)/${bam.baseName}" \\
      --cluster-file \$(pwd)/${bam.baseName}.clusters.txt \\
      --install-dir /scramble/cluster_analysis/bin \\
      --mei-refs /scramble/cluster_analysis/resources/MEI_consensus_seqs.fa \\
      --ref "\$fasta_file" \\
      --eval-meis  \\
      --eval-dels 

    mv ${bam.baseName}.vcf ${bam.baseName}.scramble.vcf
    """
}
