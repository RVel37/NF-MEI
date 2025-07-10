process MELT {
    container      'vanallenlab/melt:3159ce1'
    tag            "${bam.baseName}"
    publishDir     "${params.outdir}/melt", mode: 'copy'
    errorStrategy  'finish'

    input:
    tuple path(bam), path(bai)
    path ref_ch

    output:
    file "${bam.baseName}.melt.vcf" optional true

    script:
    """
    # stage inputs
    mkdir -p /data/bams /data/reference

    ln -s \$(readlink -f ${bam}) /data/${bam.baseName}.bam
    ln -s \$(readlink -f ${bai}) /data/${bam.baseName}.bai
    ln -s \$(readlink -f ${ref_ch})* /data/
    
    fasta=\$(ls /data | grep -E '\\.fa(sta)?\$' | head -n1)

    # concatenate all GRCh38 MEI reference zips
cat > /data/reference/mei_list.txt <<EOF
/MELT/MELTv2.0.5_patch/me_refs/Hg38/ALU_MELT.zip
/MELT/MELTv2.0.5_patch/me_refs/Hg38/LINE1_MELT.zip
/MELT/MELTv2.0.5_patch/me_refs/Hg38/SVA_MELT.zip
EOF

  java -jar /MELT/MELTv2.0.5_patch/MELT.jar Single \
      -bamfile "/data/${bam.baseName}.bam" \
      -h /data/reference/"\$fasta" \
      -t /data/reference/mei_list.txt \
      -w "\$(pwd)" \
      -n /MELT/MELTv2.0.5_patch/add_bed_files/Hg38/Hg38.genes.bed \
      -c 30 -d 10000 \
    > melt.log 2>&1 || true

    echo "printing output:"
    ls

    # only concat if MELT actually produced any VCFs
    if compgen -G "./Comparisons/*.final_comp.vcf" > /dev/null; then
        bcftools concat -a ./Comparisons/*.final_comp.vcf \
        -o data/results/melt/${bam.baseName}.melt.vcf
    fi
    """
}