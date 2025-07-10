process DEEPMEI {
    container       'xuxiaofeiscu/deepmei:latest'
    tag             "${bam.baseName}"
    publishDir      "${params.outdir}/deepmei", mode: 'copy'
    errorStrategy   'finish'

    input:
    tuple path(bam), path(bai)
    path ref_ch

    output:
    file "${bam.baseName}.deepmei.vcf" optional true

    script:
    """
    # stage inputs
    mkdir -p /root/DeepMEI/final_vcf/batch_cdgc/

    ln -s \$(readlink -f ${bam}) /root/DeepMEI/final_vcf/batch_cdgc/${bam.baseName}.bam
    ln -s \$(readlink -f ${bai}) /root/DeepMEI/final_vcf/batch_cdgc/${bam.baseName}.bai
    ln -s \$(readlink -f ${ref_ch})* /root/DeepMEI/final_vcf/batch_cdgc/
    
    echo "here is the command: /root/DeepMEI/DeepMEI -i ${bam} -r 38 -w \$(pwd) -o ${bam.baseName}"

    /root/DeepMEI/DeepMEI -i ${bam} -r 38 -w \$(pwd) -o ${bam.baseName}

    OUTDIR=\$(pwd)/DeepMEI_output/${bam.baseName}
    VCF_FILE="\${OUTDIR}/${bam.baseName}.vcf"
    
    if [ -f "\$VCF_FILE" ]; then
        mv "\$VCF_FILE" "${bam.baseName}.deepmei.vcf"
    else
        echo "\nNo VCF found!"
    fi
    """
}