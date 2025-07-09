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
    pwd
    ls

    # MOBSTER only runs correctly if inputs are in a /mobster subdir.
    # thus, create subdir with symlinks to data

    echo "Creating symlinks into /mobster/data"
    mkdir -p /mobster/data
    ln -s ${bam} /mobster/data/${bam.baseName}.bam
    ln -s ${bai} /mobster/data/${bam.baseName}.bai
    ln -s ${ref_ch}* /mobster/data/


    echo "changing to mobster dir"
    cd /mobster
    ls

    echo "and now the data dir"
    cd data; ls

    # change mobster properties from hg19 to 38
    sed -i 's|repmask/hg19_alul1svaerv.rpmsk|repmask/alu_l1_herv_sva_other_grch38_accession_ucsc.rpmsk|' /mobster/lib/Mobster.properties

    # RUN MOBSTER
    echo "running mobster..."

    cd /mobster/data

    java -Xmx8G \
    -cp ../target/MobileInsertions-0.2.4.1.jar \
    org.umcn.me.pairedend.Mobster \
    -properties ../lib/Mobster.properties \
    -in ../data/${bam.baseName}.bam \
    -sn ${bam.baseName} \
    -out ${bam.baseName}


    """

}