args <- commandArgs(trailingOnly = TRUE)
id_path <- args[1]
data1_path <- args[2]
data2_path <- args[3]

library(readxl)
library(dplyr)
library(tidyr)

# Read the data
id_data <- read_excel(id_path)
names(id_data)[2] <- "Group"

data1_data <- read_excel(data1_path)
data2_data <- read_excel(data2_path)

long_data1 <- data1_data %>%
  pivot_longer(cols = -targetName, names_to = "ID", values_to = "Value") %>%
  mutate(Batch = "Plate1")

long_data2 <- data2_data %>%
  pivot_longer(cols = -targetName, names_to = "ID", values_to = "Value") %>%
  mutate(Batch = "Plate2")

long_data <- bind_rows(long_data1, long_data2)

all_dataset <- long_data %>%
  left_join(id_data, by = "ID") %>%
  select(ID, Group, targetName, Value, Batch) %>%
  arrange(ID, targetName)

all_dataset <- all_dataset %>%
  mutate(Group = ifelse(is.na(Group), "Assay Control", Group))

# Save the dataset directly to the current working directory
saveRDS(all_dataset, "all_dataset.rds")