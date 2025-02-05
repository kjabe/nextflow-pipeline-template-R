#!/usr/bin/env nextflow

println "Current working directory (params.current_wd): ${params.current_wd}"

// Clear the workspace
process ClearWorkspace {
    script:
    """
    Rscript "${baseDir}/bin/clear_workspace.R"
    """
}

// Load data
process LoadData {
    debug true  // Add this line for debugging

    input:
    path id_path
    path data1_path
    path data2_path

    output:
    path 'all_dataset.rds'

    script:
    """
    echo "Current working directory: \$PWD"
    echo "Input files:"
    echo "ID path: ${id_path}"
    echo "data1 path: ${data1_path}"
    echo "data2 path: ${data2_path}"
    
    Rscript "${baseDir}/bin/load_data.R" "${id_path}" "${data1_path}" "${data2_path}"
    
    echo "Contents of current directory after R script:"
    ls -la
    """
}


// Run UMAP
process RunUmap {
    publishDir "${params.analysis_path}", mode: 'copy'
    debug true

    input:
    path dataset

    output:
    path 'umap_batch.pdf'
    path 'umap_group.pdf'

    script:
    """
    echo "Input dataset path: ${dataset}"
    echo "Current working directory: \$PWD"
    echo "Contents before execution:"
    ls -la
    
    Rscript "${baseDir}/bin/run_umap.R" "${dataset}"
    
    echo "Contents after execution:"
    ls -la
    """
}


// Elastic Net analysis
process ElasticNet {
    publishDir "${params.analysis_path}", mode: 'copy'
    debug true

    input:
    path dataset

    output:
    path 'final_model.rds'
    path 'auc_value.rds'
    path 'model_coefficients.rds'
    path 'roc_curve.pdf'
    path 'coefficients_plot.pdf'
    path 'batch_distribution.pdf'

    script:
    """
    echo "Input dataset path: ${dataset}"
    echo "Current working directory: \$PWD"
    echo "Contents before execution:"
    ls -la
    
    Rscript "${baseDir}/bin/elastic_net.R" "${dataset}"
    
    echo "Contents after execution:"
    ls -la
    """
}

workflow {
    clear_workspace = ClearWorkspace()

    // Create channels for input files with explicit error checking
    id_file = Channel
        .fromPath('./data/your_id_file_name.xlsx')
        .ifEmpty { error "Cannot find ID file: ./data/your_id_file_name.xlsx" }

    data1_file = Channel
        .fromPath('./data/your_data1_file_name.xlsx')
        .ifEmpty { error "Cannot find data1 file: ./data/your_data1_file_name.xlsx" }

    data2_file = Channel
        .fromPath('./data/your_data2_file_name.xlsx')
        .ifEmpty { error "Cannot find data2 file: ./data/your_data2_file_name.xlsx" }
    
    // Execute processes in order
    load_data = LoadData(id_file, data1_file, data2_file)
    run_umap = RunUmap(load_data)
    elastic_net = ElasticNet(load_data)
}
