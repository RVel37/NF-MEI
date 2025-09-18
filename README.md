> This file (readme) currently consists of notes to myself. To be cleaned up and rewritten.

Tools to include: Scramble, MELT, Mobster, DeepMEI, TEMP2, Xtea


----------------------------------
# General
- Discordant reads: PE reads which don't align to ref genome in expected orientation/distance/location
- Split reads: individual reads aligning to 2+ separate locations - indicates the presence of a breakpoint

# TEST DATA
We are using scramble's `test.bam` and `test.bam.bai` files as test runs (to configure pipeline) for several reasons:
- Small and fast: files cover small region (chr3:70,000,000-71,000,000), so they run quickly and are easy to handle.
- Reproducible: They are distributed with the tool, so anyone can use the same data for comparison or debugging.
- Known output: Expected outputs are well-documented, making it easy to check if pipeline/other MEI tools are working as expected.

Limitations:
Test files are fine for basic benchmarking/testing pipeline, but won't represent real-world dataset size and complexity. **Will use a 1kGP Exome for further testing, as the reference genome provided by scramble's validation directory appears to be incompatible with MELT.**

For final benchmarking will use the HG002 data + internal BAMs from NHS.

# reference genome
wget https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta

# docker
Local: have to have pulled it first, before running
DNAnexus: dont have to pull - will automatically fetch the required docker image if available on dockerhub

# tracking time taken
Nextflow comes wih in-built wall clock time and memory usage tracking. try:
`nextflow run main.nf -with-report report.html -with-trace trace.txt -with-timeline timeline.html -with-dag flowchart.png`

# evaluating deletions
Provided as optional arg by MELT, SCRAMble, ... 
Choosing to add this in, despite NHS pipelines already having a dedicated CNV caller. MEIs often cause small deletions/rearrangements near insertion sites -> detecting deletions helps find breakpoints and improve MEI genotyping. As the tools carry out clustering and local assembly around candidate MEI sites, they may catch these deletions with greater accuracy than general CNV callers.

----------------------------------
# INTERACTIVE TESTS
 
## Scramble
 
https://github.com/GeneDx/scramble/
 
Used the SWGLH image after first trying to run the Docker provided in the Github which was broken due to Rblast (updated, can't install an older version as it is managed through BiocManager, and BiocManager requires a different version of R to scramble's)
 
(swglh/scramble:1.0 is somehow newer than swglh/scramble:latest)
 
```bash
docker pull swglh/scramble:1.0
docker run -it --rm -v $(pwd)/data:/data swglh/scramble:1.0 bash
```
Scramble provides test data: `test.bam` and `test.bam.bai`.

### scramble is run in 2 parts
 
Because of the way I ran it from inside the scramble directory, i had to use full paths for the 2nd part otherwise `SCRAMble.R` couldn't find the files - perhaps it ought to be run outside of the scramble directory.
 
``` bash
cluster_identifier    validation/test.bam > validation/test.clusters.txt
 
Rscript --vanilla cluster_analysis/bin/SCRAMble.R     --out-name ${PWD}/test     --cluster-file ${PWD}/validation/test.clusters.txt --install-dir cluster_analysis/bin     --mei-refs ${PWD}/cluster_analysis/resources/MEI_consensus_seqs.fa     --ref ${PWD}/validation/test.fa     --eval-dels     --eval-meis
```
Output:
- tab delim txt file `test.clusters.txt` with clipped cluster consensus sequences
- VCF (if `ref.fa` provided)


Concatenate all the MEI reference zip files
```bash
cat <<EOF > data/reference/mei_list.txt
/MELT/MELTv2.0.5_patch/me_refs/Hg38/ALU_MELT.zip
/MELT/MELTv2.0.5_patch/me_refs/Hg38/LINE1_MELT.zip
/MELT/MELTv2.0.5_patch/me_refs/Hg38/SVA_MELT.zip
EOF
```
```bash
java -jar MELTv2.0.5_patch/MELT.jar Single -bamfile data/bams/test.bam -h data/reference/test.fa -t data/reference/mei_list.txt -w data/results/ -n MELTv2.0.5_patch/add_bed_files/Hg38/Hg38.genes.bed -c 30 
```

MELT runs each MEI type INDEPENDENTLY. This means it produces 3 VCFs per sample

> Melt is closed-source and only free for research purposes

## MOBSTER

Created in 2014, written in Java. Similar idea to others: find discordant and split-reads in input BAM file -> align to custom Mobilome.

- Discordant reads which have at least 1 uniquely mapped read: other read used to anchor the possible insertion event. The mates of anchoring readsare mapped to the mobilome.
- If both reads are uniquely mapped to reference, both will be aligned to the mobilome.
- If read is clipped, clipped sequence is mapped to mobilome and investigated for a poly-A or poly-T stretch.

Discordant & SRs are CLUSTERED according to things like the anchor seqs, whether they are 5' or 3', what ME  family they map to. 

Filters where <5 supporting reads. 

Mobster's mobilome uses a subset of RepBase consensus sequences - **54 MEs thought to be active in humans**
- May be OUTDATED

When making this task, the difficulty came from needing to run it in a /mobster subdirectory because the Mobster.properties file includes relative paths. 

## DEEPMEI

Most recently developed tool. Uses most complicated algorithm out of the tools we're examining (tensorflow)

The Docker version does not run as advertised in the github readme for two reasons.
1. From looking through the bash script, it seems to append `.bam` to my input (which it treats as the basename). It then can't find `sample.bam.bam`. I think specifying -o (output file name) is the solution as it will treat this as the basename instead. 
2. It expects to find inputs in a specific subdir `/root/DeepMEI/final_vcf/batch_cdgc/`. 

To solve this:

- I first ran
`docker run -it -v /home/dnanexus/data:/root/data/ -w /root xuxiaofeiscu/deepmei:latest /bin/bash`

- then inside the container
```
mkdir -p /root/DeepMEI/final_vcf/batch_cdgc/
cp /root/data/deepmei_input/HG01879.bam /root/DeepMEI/final_vcf/batch_cdgc/
cp /root/data/deepmei_input/HG01879.bam.bai /root/DeepMEI/final_vcf/batch_cdgc/
./DeepMEI/DeepMEI -i /root/data/deepmei_input/HG01879.bam -r 38 -w /root/data/ -o HG01879
```
(a better solution if we opt to use this tool would be to fix the bash script and create own docker image, instead of hardcoding hotfixes in the NF process. The tool has an MIT license.)

DeepMEI's outputs go in <workingdir specified in -o>/DeepMEI_output/

--------------------

# NOTE FOR ACTUAL VALIDATION

The HG002 BAMs are accessed from the NIH FTP site. Specifically these are the Illumina Novoalign 2x250, 75x BAMs.
The readme states the GRCh38 reference file is available here: ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_plus_hs38d1_analysis_set.fna.gz

# RUNNING ON DNANEXUS

https://documentation.dnanexus.com/user/running-apps-and-workflows/running-nextflow-pipelines#running-a-nextflow-pipeline-executable-app-or-applet

From command line: 

1. build:
`dx build --nextflow`

2. run:
(modify applet and output names)
```bash
dx run project-J00J2YQ49jJKz0Xq6yB4qB4x:applet-J2JYzXj49jJJ2b2fZKP1xyZx \
> -i debug=true \
> --destination UsrRay:/meis/outputs/wf1_1kgp \
> --brief -y
```
