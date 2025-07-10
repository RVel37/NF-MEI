process MOBTOVCF {
    container 'rvel37/mobstertovcf:1.0'
    publishDir "${params.outdir}/mobster", mode: 'copy'
    errorStrategy 'finish'

    input:
    path mob_txt_file

    output:
    path "${mob_txt_file.baseName}.vcf"

    script:
    """
    java -jar /mobstertovcf/MobsterVCF-0.0.1-SNAPSHOT.jar \
      -file ${mob_txt_file.getName()} \
      -out ${mob_txt_file.baseName}.vcf
    """
}