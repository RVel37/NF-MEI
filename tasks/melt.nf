process MELT {
    container 'vanallenlab/melt:3159ce1'

    tag "${bam.baseName}"

    publishDir "${params.outdir}/melt", mode: 'copy'

    errorStrategy 'finish'

    input:
    tuple path(bam), path(bai)
    path(ref_ch)

    output:
    file("${bam.baseName}.melt.vcf")

    script:
    """
    # create directory layout
    mkdir -p data/bams data/reference data/results/melt

    ln -s ${bam} data/bams/${bam.baseName}.bam
    ln -s ${bai} data/bams/${bam.baseName}.bam.bai
    cp ${ref_ch} data/reference/

    fasta_file=\$(ls ${ref_ch} | grep -E '\\.fa(sta)?\$' | head -n1)

    # melt asks for absolute path to bam file
    bam_path=\$(readlink -f ${bam})

    # concatenate all GRCh38 MEI reference zips
    cat > data/reference/mei_list.txt <<EOF
    /MELT/MELTv2.0.5_patch/me_refs/Hg38/ALU_MELT.zip
    /MELT/MELTv2.0.5_patch/me_refs/Hg38/LINE1_MELT.zip
    /MELT/MELTv2.0.5_patch/me_refs/Hg38/SVA_MELT.zip
    EOF

    java -jar /MELT/MELTv2.0.5_patch/MELT.jar Single \
        -bamfile "\$bam_path" \
        -h data/reference/"\$fasta_file" \
        -t data/reference/mei_list.txt \
        -w data/results/melt_${bam.baseName} \
        -n /MELT/MELTv2.0.5_patch/add_bed_files/Hg38/Hg38.genes.bed \
        -c 30 \
        -d 10000 > melt.log 2>&1 || true
                ### REMEMBER TO REMOVE D FLAG AFTER TESTING SMALL DATASET ###

    # MELT automatically fails if no hits are found. Instead, store this in a log file. 

    if grep -q "No hits found... Fail!" melt.log && ! grep -E -q 'Exception|Error|Failed' melt.log; then
        echo "No hits found but no critical error, continuing."
        touch ${bam.baseName}.melt.vcf
        exit 0
    else
        # If MELT produced a VCF, rename it
        OUTVCF="data/results/melt_${bam.baseName}/results.vcf"
        if [ -f "\$OUTVCF" ]; then
            mv "\$OUTVCF" ${bam.baseName}.melt.vcf
        fi

        # Serious errors should still crash pipeline
        grep -E -q 'Exception|Error|Failed' melt.log && exit 1 || exit 0
    fi
    """
}