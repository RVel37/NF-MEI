process MOBSTER {
    container 'swglh/mobster:0.2.4.1'
    tag "${bam.baseName}"
    publishDir "${params.outdir}/mobster", mode: 'copy'
    errorStrategy 'finish'

    input:
    tuple path(bam), path(bai)
    path ref_ch

    output:
    file "${bam.baseName}.txt" optional true

    script:
    """
    # MOBSTER only runs correctly if inputs are in a /mobster subdir.
    # thus, create subdir with symlinks to data.

    # first assign working dir as an environment variable
    ROOT_DIR=\$(pwd)

    echo "Creating symlinks into /mobster/data"
    mkdir -p /mobster/data
    ln -s \$(readlink -f ${bam}) /mobster/data/${bam.baseName}.bam
    ln -s \$(readlink -f ${bai}) /mobster/data/${bam.baseName}.bai
    ln -s \$(readlink -f ${ref_ch})* /mobster/data/

    cd /mobster/data; ls

    # change 'Mobster.properties' reference file from hg19 to 38
    sed -i 's|repmask/hg19_alul1svaerv.rpmsk|repmask/alu_l1_herv_sva_other_grch38_accession_ucsc.rpmsk|' /mobster/lib/Mobster.properties

    # RUN MOBSTER
    echo "running mobster..."

    java -Xmx8G \
    -cp ../target/MobileInsertions-0.2.4.1.jar \
    org.umcn.me.pairedend.Mobster \
    -properties ../lib/Mobster.properties \
    -in ${bam.baseName}.bam \
    -sn ${bam.baseName} \
    -out ${bam.baseName}

    # move any outputs back to root working dir
    cp /mobster/data/${bam.baseName}*.txt \$ROOT_DIR
    
    """
}