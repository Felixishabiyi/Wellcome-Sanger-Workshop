#Getting the files from NCBI SRA
fastq-dump --split-files ERR5743893

#First, lets create a directory to save our fastQC outputs to:
mkdir -p QC_Reports

#Quality check
fastqc ERR5743893_1.fastq ERR5743893_2.fastq --outdir QC_Reports

#Visualizing results in MultiQC
multiqc . 

#Aligning to the corona virus reference genome
mkdir Mapping

#Indexing to reference genome
bwa index MN908947.fasta

#Mapping to reference genome
bwa mem MN908947.fasta ERR5743893_1.fastq ERR5743893_2.fastq > Mapping/ERR5743893.sam

#Changing directory to Mapping
cd Mapping
ls -lhrt

#@ - number of threads

#S - input is a SAM file

#b - output should be a BAM file

#to save space convert sam to bam
cd ..
samtools view -@ 20 -S -b Mapping/ERR5743893.sam > Mapping/ERR5743893.bam

#Sorting
samtools sort -@ 32 -o Mapping/ERR5743893.sorted.bam Mapping/ERR5743893.bam

#Indexing, then Visualize
samtools index Mapping/ERR5743893.sorted.bam

#Variant #Calling
samtools faidx MN908947.fasta

#Identifcation of Variant
freebayes -f MN908947.fasta Mapping/ERR5743893.sorted.bam  > ERR5743893.vcf

#File compression
bgzip ERR5743893.vcf
tabix ERR5743893.vcf.gz

#NEXTFLOW

#Ensuring that the java the nextflow will run is up to date.
#checking the version of java
java -version

#Downloading nextflow
curl -fsSL get.nextflow.io | bash

#Addding to our path
mv nextflow ~/bin/

#Installation through conda, setting up conda channels
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge

#Creating a Nextflow conda environment
conda create --name nextflow nextflow

#activating the environment
conda activate nextflow

#to ensure nextflow is running
nextflow help

#installing singularity
sudo apt install -y runc cryptsetup-bin
wget -O singularity.deb https://github.com/sylabs/singularity/releases/download/v3.11.4/singularity-ce_3.11.4-jammy_amd64.deb
sudo dpkg -i singularity.deb
rm singularity.deb

#Downloading samples for our nextflow pipeline
#should be in a text file 
ERR5556343,SRR13500958,ERR5743893,ERR5181310,ERR5405022

#a for loop to create a fastq dump on the files
for i in $(cat samples.txt);do fastq-dump --split-files $i;done

#compressing the fastq files we just downloaded
gzip *.fastq

#creating a directory "data" and moving the fastq files there
mkdir data
mv *.fastq.gz data

#nf pipelines prefer their input files to be in csv file
mkdir data
mv *.fastq.gz data

#using a python script to creating a csv file
wget -L https://raw.githubusercontent.com/nf-core/viralrecon/master/bin/fastq_dir_to_samplesheet.py

#running the script
python3 fastq_dir_to_samplesheet.py data samplesheet.csv -r1 _1.fastq.gz -r2 _2.fastq.gz

#printing out the csv file
cat samplesheet.csv

#Running nextflow
#activating the nextflow environment
conda activate nextflow

#running nextflow
nextflow run nf-core/viralrecon -profile singularity \
--max_memory '12.GB' --max_cpus 4 \
--input samplesheet.csv \
--outdir results/viralrecon \
--protocol amplicon \
--genome 'MN908947.3' \
--primer_set artic \
--primer_set_version 3 \
--skip_kraken2 \
--skip_assembly \
--skip_pangolin \
--skip_nextclade \
--platform illumina

#checking the results in the directory
cd results/viralrecon
ls

#to check the space the work directory occupied
du -sh work

#to remove the work directory
rm -rf work
















