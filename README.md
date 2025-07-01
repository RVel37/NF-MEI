Note: this file (readme) currently consists of notes to myself. To be cleaned up and rewritten.


# Data locations

IGSR (international genome sample resource) - provides open data from range of sources including 1KGP.


https://www.internationalgenome.org/data


https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/


Readme for 1kgp phase 3 alignment pipeline (bwamem > samtools > gatk3 > cramtool)
https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/README.1000genomes.GRCh38DH.alignment


https://www.ncbi.nlm.nih.gov/dbvar/studies/nstd144/download/

----------------------------------
# TEST DATA - FROM SCRAMBLE
We are using scramble's `test.bam` and `test.bam.bai` files as test runs (to configure pipeline) for several reasons:

- Small and fast: files cover small region (chr3:70,000,000-71,000,000), so they run quickly and are easy to handle.
- Reproducible: They are distributed with the tool, so anyone can use the same data for comparison or debugging.
- Known output: Expected outputs are well-documented, making it easy to check if pipeline/other MEI tools are working as expected.

Limitations:
Test files are fine for basic benchmarking/testing pipeline, but won't represent real-world dataset size and complexity. For final benchmarking will use the HG002 data + internal BAMs from NHS.


# reference genome
wget https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta

# docker
Local: have to have pulled it first, before running
DNAnexus: dont have to pull - will automatically fetch the required docker image if available on dockerhub

# tracking time taken
Nextflow comes wih in-built wall clock time and memory usage tracking. try:
`nextflow run main.nf -with-report report.html -with-trace trace.txt -with-timeline timeline.html -with-dag flowchart.png`

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

## scramble is run in 2 parts
 
Because of the way I ran it from inside the scramble directory, i had to use full paths for the 2nd part otherwise `SCRAMble.R` couldn't find the files - perhaps it ought to be run outside of the scramble directory.
 
``` bash
cluster_identifier    validation/test.bam > validation/test.clusters.txt
 
Rscript --vanilla cluster_analysis/bin/SCRAMble.R     --out-name ${PWD}/test     --cluster-file ${PWD}/validation/test.clusters.txt --install-dir cluster_analysis/bin     --mei-refs ${PWD}/cluster_analysis/resources/MEI_consensus_seqs.fa     --ref ${PWD}/validation/test.fa     --eval-dels     --eval-meis
```
 
Output (for `--eval-meis`):
- tab delim txt file `test.clusters.txt` with clipped cluster consensus sequences
- VCF (if `ref.fa` provided)
 
 30 June:
Reference.fa for nextflow is currently test.fa provided in the scramble/validation directory. (`--ref ${ref_dir}/test.fa`) May want to change this to the standard GRCh38 reference? 

### SCRAMBLE ISSUES
Had significant difficulty figuring out how to pass in the reference fasta file, despite channels working correctly. Turns out this issue was specific to how `SCRAMble.R` handles paths. Issue was resolved in slightly unorthodox way:
```bash
    # absolute path
    fasta_file=\$(readlink -f "\$fasta_file")
```
Where we provide an absolute path within the script. Unsure if this will need further corrections for DNAnexus. 

--------------------

# NOTE FOR ACTUAL VALIDATION

The HG002 BAMs are accessed from the NIH FTP site. Specifically these are the Illumina Novoalign 2x250, 75x BAMs.
The readme states the GRCh38 reference file is available [here](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_plus_hs38d1_analysis_set.fna.gz)


