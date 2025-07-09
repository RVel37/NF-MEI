process MOBSTER {
    container 'swglh/mobster:0.2.4.1'
    tag "${bam.baseName}"
    publishDir "${params.outdir}/mobster", mode: 'copy'
    errorStrategy 'finish'

    input:
    tuple path(bam), path(bai)
    path ref_ch

    output:
    file "${bam.baseName}.mobster.vcf" optional true

    script:
    """
    mkdir -p mobster/data/bams mobster/data/reference mobster/data/results

    # symlink inputs

    ln -s ${bam} mobster/data/bams/${bam.baseName}.bam
    ln -s ${bai} mobster/data/bams/${bam.baseName}.bam.bai
    ln -s ${ref_ch} mobster/data/reference/

    fasta=\$(ls mobster/data/reference | grep -E '\\.fa(sta)?\$' | head -n1)
    bam_path=\$(readlink -f ${bam})

    # change dir & alter Mobster.properties to take grch38 reference
    
    cd mobster/
    sed -i 's|repmask/hg19_alul1svaerv.rpmsk|repmask/alu_l1_herv_sva_other_grch38_accession_ucsc.rpmsk|' \$(pwd)/lib/Mobster.properties

    cd data/

    java -Xmx8G -cp target/MobileInsertions-0.2.4.1.jar org.umcn.me.pairedend.Mobster \
    -properties lib/Mobster.properties \
    -in "data/bams/${bam.baseName}.bam" \
    -sn "${bam.baseName}" \
    -out "results/${bam.baseName}"
    
    # rename VCF
    cp results/${bam.baseName}.vcf ${bam.baseName}.mobster.vcf

    """

}