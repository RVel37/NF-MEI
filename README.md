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

Small and Fast: files cover small region (chr3:70,000,000-71,000,000), so they run quickly and are easy to handle.
Reproducible: They are distributed with the tool, so anyone can use the same data for comparison or debugging.
Known Output: Expected outputs are well-documented (see README.md), making it easy to check if pipeline and other MEI tools are working as expected.

Limitations:
Test files are fine for basic benchmarking/testing pipeline, but won't represent real-world dataset size and complexity. For final benchmarking will also include larger and more diverse BAMs.


# reference genome
wget https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta

# docker
Local: have to have pulled it first, before running
DNAnexus: dont have to pull - will automatically fetch the required docker image if available on dockerhub

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
 


