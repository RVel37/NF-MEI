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
    mkdir -p data/bams data/reference
    ln -s ${bam} data/bams/${bam.baseName}.bam
    ln -s ${bai} data/bams/${bam.baseName}.bam.bai
    cp ${ref_ch} data/reference/
    
    fasta=\$(ls data/reference | grep -E '\\.fa(sta)?\$' | head -n1)
    bam_path=\$(readlink -f ${bam})

    # concatenate all GRCh38 MEI reference zips
    cat > data/reference/mei_list.txt <<EOF
    /MELT/MELTv2.0.5_patch/me_refs/Hg38/ALU_MELT.zip
    /MELT/MELTv2.0.5_patch/me_refs/Hg38/LINE1_MELT.zip
    /MELT/MELTv2.0.5_patch/me_refs/Hg38/SVA_MELT.zip
    EOF

  java -jar /MELT/MELTv2.0.5_patch/MELT.jar Single \
      -bamfile "\$bam_path" \
      -h data/reference/"\$fasta" \
      -t data/reference/mei_list.txt \
      -w "\$(pwd)" \
      -n /MELT/MELTv2.0.5_patch/add_bed_files/Hg38/Hg38.genes.bed \
      -c 30 -d 10000 \
    > melt.log 2>&1 || true

    # only concat if MELT actually produced any VCFs
    if compgen -G "./Comparisons/*.final_comp.vcf" > /dev/null; then
        bcftools concat -a ./Comparisons/*.final_comp.vcf \
        -o data/results/melt/${bam.baseName}.melt.vcf
    fi
    """
}