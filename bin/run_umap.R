library(readxl)
library(dplyr)
library(umap)
library(ggplot2)
library(tidyr)

# Get the input file path from command line arguments
args <- commandArgs(trailingOnly = TRUE)
input_file <- args[1]

# Print debugging information
cat("Reading input file:", input_file, "\n")

# Read the input dataset
all_dataset <- readRDS(input_file)

# Filter and transform data for UMAP
all_dataset_filtered <- all_dataset %>% filter(Group != "NULISA Assay Control")
all_dataset_wide <- all_dataset_filtered %>%
  select(-Group) %>%
  spread(key = targetName, value = Value)

# Print debugging information
cat("Dimensions of wide dataset:", dim(all_dataset_wide)[1], "x", dim(all_dataset_wide)[2], "\n")

# Prepare data for UMAP
umap_data <- as.matrix(all_dataset_wide %>% select(-ID, -Batch))
umap_result <- umap(umap_data, n_neighbors = 15, min_dist = 0.1)

umap_df <- data.frame(UMAP1 = umap_result$layout[,1],
                      UMAP2 = umap_result$layout[,2],
                      ID = all_dataset_wide$ID,
                      Batch = all_dataset_wide$Batch)

umap_df <- umap_df %>%
  inner_join(all_dataset_filtered %>% distinct(ID, Group), by = "ID")

# Create and save batch plot
umap_batch <- ggplot(umap_df, aes(x = UMAP1, y = UMAP2, color = Batch)) +
  geom_point() +
  labs(title = "UMAP (all data)",
       x = "UMAP 1",
       y = "UMAP 2") +
  theme_classic()

# Save batch plot
cat("Saving batch plot...\n")
pdf("umap_batch.pdf", width = 4, height = 3)
print(umap_batch)
dev.off()

# Create and save group plot
umap_group <- ggplot(umap_df, aes(x = UMAP1, y = UMAP2, color = Group)) +
  geom_point() +
  labs(title = "UMAP (all data)",
       x = "UMAP 1",
       y = "UMAP 2") +
  theme_classic()

# Save group plot
cat("Saving group plot...\n")
pdf("umap_group.pdf", width = 4, height = 3)
print(umap_group)
dev.off()

# Verify files were created
cat("Checking output files:\n")
cat("umap_batch.pdf exists:", file.exists("umap_batch.pdf"), "\n")
cat("umap_group.pdf exists:", file.exists("umap_group.pdf"), "\n")