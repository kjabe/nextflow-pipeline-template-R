# Nextflow Pipeline Template with R

This repository contains a template for a Nextflow pipeline that integrates R scripts for data analysis. The pipeline includes processes for clearing the workspace, loading data, running UMAP, and performing Elastic Net analysis.


## Prerequisites

- [Nextflow](https://www.nextflow.io/)
- [R](https://www.r-project.org/) (version 4.4.0 or higher)
- [renv](https://rstudio.github.io/renv/) for R package management

## Setup

1. Clone the repository:
    ```sh
    git clone https://github.com/kjabe/nextflow-pipeline-template-R.git
    cd nextflow-pipeline-template-R
    ```

2. Install Nextflow:
    ```sh
    curl -s https://get.nextflow.io | bash
    ```

3. Initialize the R environment using renv:
    ```sh
    Rscript -e "renv::restore()"
    ```

## Pipeline Overview

The pipeline consists of the following processes:

1. **ClearWorkspace**: Clears the R workspace.
2. **LoadData**: Loads and preprocesses the data from Excel files.
3. **RunUmap**: Runs UMAP dimensionality reduction on the dataset.
4. **ElasticNet**: Performs Elastic Net analysis on the dataset.

## Running the Pipeline

1. Ensure your data files are placed in the data directory.
2. Update the main.nf file with the correct paths to your data files.
3. Run the pipeline:
    ```sh
    ./nextflow run main.nf
    ```

## Configuration

The pipeline configuration is managed through the nextflow.config file. You can set the paths for data directories and other parameters here.

## R Scripts

The bin directory contains the R scripts used in the pipeline:

- clear_workspace.R: Clears the R workspace.
- load_data.R: Loads and preprocesses the data.
- run_umap.R: Runs UMAP dimensionality reduction.
- elastic_net.R: Performs Elastic Net analysis.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contact

For any questions or issues, please open an issue on this repository.
