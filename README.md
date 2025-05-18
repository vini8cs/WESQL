# WESQL

Whole Exome Sequencing (WES) Quality Control Pipeline

<!-- vscode-markdown-toc -->
* 1. [Author Identification](#AuthorIdentification)
* 2. [Pipeline Description](#PipelineDescription)
* 3. [Usage Instructions](#UsageInstructions)
	* 3.1. [Clone the Repository](#ClonetheRepository)
	* 3.2. [Install Dependencies](#InstallDependencies)
	* 3.3. [Prepare Input Files](#PrepareInputFiles)
	* 3.4. [Run the Pipeline](#RunthePipeline)
	* 3.5. [Tools](#Tools)
	* 3.6. [Outputs and Expected Results](#OutputsandExpectedResults)
* 4. [System Requirements](#SystemRequirements)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

##  1. <a name='AuthorIdentification'></a>Author Identification

- **Author:** Vinícius Castro Santos
- **Contact:** vini8cs@gmail.com

##  2. <a name='PipelineDescription'></a>Pipeline Description
This repository contains a Nextflow-based pipeline for genome analysis. The pipeline processes CRAM files, performs alignment statistics, computes genome coverage, infers biological sex, and evaluates DNA contamination levels. It generates comprehensive reports in Markdown and PDF formats, including visualizations and detailed metrics.

##  3. <a name='UsageInstructions'></a>Usage Instructions

###  3.1. <a name='ClonetheRepository'></a>Clone the Repository

```bash
git clone https://github.com/vini8cs/WESQL.git
cd WESQL
```

###  3.2. <a name='InstallDependencies'></a>Install Dependencies

Ensure all dependencies (listed below) are installed and accessible in your environment.

- [Nextflow](https://www.nextflow.io/docs/latest/install.html)
- [Docker](https://docs.docker.com/engine/install/ubuntu/#install-from-a-package)

###  3.3. <a name='PrepareInputFiles'></a>Prepare Input Files

- **CRAM Files**: Provide CRAM files for the samples to be analyzed. Examples can be downloaded [here](https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/data/CEU/NA06994/exome_alignment/).

- **BED File**: Specify a BED file with regions of interest. Examples can be downloaded [here](https://www.twistbioscience.com/resources/data-files/twist-exome-20-bed-files).

These files should be specified in a JSON file based on the provided template `params.json.example`. The JSON file organizes the input data and ensures compatibility with the pipeline.

- **Kraken database**:  

  - **Database Selection**:  
    Any Kraken-compatible database containing human and non-human sequences can be used. Larger databases improve the identification of contaminants and reduce the number of unclassified reads. However, for most use cases, smaller databases like [Standard-8](https://benlangmead.github.io/aws-indexes/k2) are recommended due to their balance between size, speed, and accuracy. The Standard-8 database is compact and efficient, making it suitable for preliminary contamination analysis.

  - **Downloading and Extracting the Database**:  
    To set up the Standard-8 database, follow these steps:
    ```bash
    mkdir kraken_db
    cd kraken_db
    wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20250402.tar.gz
    tar -xf k2_standard_08gb_20250402.tar.gz
    ```
    This will create a directory containing the necessary files for Kraken2 to perform contamination analysis.

  - **Alternative Databases**:  
    If a more comprehensive analysis is required, larger databases can be used. These are available [here](https://benlangmead.github.io/aws-indexes/k2). Larger databases may improve classification accuracy but require more computational resources.

  - **Integrating the Database into the Pipeline**:  
    To use the database in the pipeline, its path must be specified in the `params.nf` configuration file. A template file (`params.nf.example`) is provided in the repository to guide users in setting up the parameters. Update the `kraken_db` parameter in the configuration file to point to the extracted database directory.

###  3.4. <a name='RunthePipeline'></a>Run the Pipeline

```bash
nextflow run main.nf -params-file <path/to/json> [ -w path/to/workdir --outdir <path/to/outdir_folder> --author <author_name> --kraken2_cpus <int> --debug -bg -resume -stub -profile stub ]
```
- Mandatory:

    - **params-file**: Path to a JSON file containing input parameters for the pipeline. This file should define all necessary inputs (e.g., CRAM files, BED file, etc.) in structured format.

- Optional:

    - **w**: Defines a custom working directory where Nextflow stores intermediate files. If not specified, Nextflow will use the default `.nextflow` directory.

    - **outdir**: Output directory where all final results (e.g., quality control reports, aligned reads, summary files) will be saved.  Nextflow will use the default `results` directory.

    - **author**: Sets the author name in the output report.

    - **debug**: Enables debug mode, which may provide additional log output or preserve intermediate files for troubleshooting purposes.

    - **bg**: Runs the pipeline in the background (useful for long-running jobs). This option is often used when launching from a script or terminal session.

    - **resume**: Resumes the pipeline execution from the last successful step. This is particularly useful if the process was interrupted or if you are re-running with unchanged input files.

    - **kraken2_cpus**: Specifies the number of CPU cores to allocate for Kraken2, a taxonomic sequence classification system. Increasing the number of CPUs can improve processing speed for large datasets. Deafult: 30

    - **stub**: `stub` should be used with `-profile stub` and it's onçy for testing purposes.


###  3.5. <a name='Tools'></a>Tools

The pipeline relies on the following tools, each chosen for their specific strengths in genome analysis:

- **Samtools**:  
  Samtools is a widely used suite of tools for manipulating and analyzing high-throughput sequencing data in SAM, BAM, and CRAM formats. It is employed in this pipeline for the following reasons:  
  - **Alignment Statistics**: Samtools provides detailed alignment metrics, such as the number of mapped reads, unmapped reads, and duplicate reads. These metrics are essential for assessing the quality of sequencing data and ensuring that the alignment process was successful.  
  - **Depth Calculation**: Samtools efficiently calculates the depth of coverage across the genome, which is critical for identifying regions with sufficient sequencing depth for downstream analyses. This ensures that the data meets the required standards for variant calling or other genomic studies.  
  - **FASTQ Conversion**: Samtools can convert CRAM files back to FASTQ format, enabling downstream analyses that require raw sequencing reads. This is particularly useful for contamination analysis or re-alignment tasks.

- **Kraken2**:  
  Kraken2 is a highly accurate and efficient taxonomic classification tool for metagenomic and genomic data. It is used in this pipeline for contamination analysis due to the following reasons:  
  - **Contamination Detection**: Kraken2 identifies and quantifies the presence of non-human DNA in the sequencing data. The acurracy can increase depending on the database that are used. In this pipeline, a standard database (Standard-8) was enough for a preliminary analysis of the non-human contamination. This is crucial for ensuring the integrity of the genomic analysis, as contamination can lead to false conclusions or skewed results.  
  - **Taxonomic Classification**: Kraken2 provides detailed taxonomic information about the contaminating organisms, allowing researchers to trace the source of contamination and take corrective actions.  
  - **Speed and Accuracy**: Kraken2 uses a k-mer-based approach with a compact database structure, making it both fast and memory-efficient while maintaining high accuracy. This makes it ideal for large-scale genomic datasets.

These tools were selected for their reliability, performance, and widespread adoption in the genomics community, ensuring robust and reproducible results for the analyses performed in this pipeline.

###  3.6. <a name='OutputsandExpectedResults'></a>Outputs and Expected Results

The pipeline generates the following outputs:

- **Alignment Statistics**: Summary of alignment metrics (e.g., total reads, mapped reads) saved in the `AlignmentStatistics` folder for each sample.
- **Coverage Analysis**: Coverage distribution plots and depth statistics saved in the `Coverage` folder for each sample and in `Coverage_plots` folder.
- **Sex Inference**: Likely biological sex determined based on genomic coverage.
- **Contamination Analysis**: Contamination levels and taxonomic composition saved in the `Contamination` folder for each sample.
- **Reports**:
    - **Markdown report** (`report.md`).
    - **PDF report** (`report.pdf`).

Examples of output files and logs can be found here in the path `tests/example_outputs`. Log files are located in the `pipeline_info`folder.

##  4. <a name='SystemRequirements'></a>System Requirements

The machine running this pipeline must meet the following minimum requirements:

- **RAM**: At least **12GB** of RAM is required to ensure smooth execution of the pipeline, especially during Kraken2 contamination analysis and Samtools operations.
- **CPU**: Multi-core processor recommended (e.g., 4 or more cores) for parallel processing.
- **Disk Space**: Sufficient storage for input files, intermediate files, and outputs. At least **50GB** of free space is recommended, depending on the size of the input data.
- **Operating System**: Linux-based systems are recommended for compatibility with Nextflow and Docker.

Failure to meet these requirements may result in performance issues or pipeline failures.
