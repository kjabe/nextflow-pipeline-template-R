library(dplyr)
library(caret)
library(glmnet)
library(pROC)
library(tidyr)
library(ggplot2)
library(gridExtra)

# Get the input file path from command line arguments
args <- commandArgs(trailingOnly = TRUE)
input_file <- args[1]

# Read the input dataset
all_dataset <- readRDS(input_file)

# Filter and prepare data
filtered_data <- all_dataset %>%
  filter(Group != "Assay Control", Group %in% c("Group1", "Group2"))
filtered_data$Group <- as.factor(filtered_data$Group)

# Transform data to wide format
wide_data <- filtered_data %>% 
  pivot_wider(names_from = targetName, values_from = Value)

# Set seed for reproducibility
set.seed(123)

# Split data (stratified by Batch)
trainIndex <- createDataPartition(wide_data$Batch, p = 0.7, list = FALSE, times = 1)
train_data <- wide_data[trainIndex, ]
test_data <- wide_data[-trainIndex, ]

# Plot batch distribution
train_plot <- ggplot(train_data, aes(x = Batch)) +
  geom_bar(fill = "blue", alpha = 0.7) +
  labs(title = "Batch Distribution in Training Data",
       x = "Batch",
       y = "Count") +
  theme_minimal()

test_plot <- ggplot(test_data, aes(x = Batch)) +
  geom_bar(fill = "red", alpha = 0.7) +
  labs(title = "Batch Distribution in Testing Data",
       x = "Batch",
       y = "Count") +
  theme_minimal()

# Save batch distribution plot
pdf("batch_distribution.pdf", width = 3, height = 3)
grid.arrange(train_plot, test_plot, ncol = 1, 
             top = "Batch Distribution in Train and Test Data")
dev.off()

# Prepare matrices for training
X_train <- as.matrix(train_data %>% select(-ID, -Group, -Batch))
y_train <- train_data$Group

# Prepare matrices for testing
X_test <- as.matrix(test_data %>% select(-ID, -Group, -Batch))
y_test <- test_data$Group

# Normalize predictors
X_train <- scale(X_train)
X_test <- scale(X_test)

# Train Elastic Net model with cross-validation
n_repeats <- 10
alpha_value <- 0.5
best_lambdas <- numeric(n_repeats)

for (i in 1:n_repeats) {
  set.seed(123 + i)
  cv_fit <- cv.glmnet(X_train, y_train, alpha = alpha_value, family = "binomial")
  best_lambdas[i] <- cv_fit$lambda.min
}

# Compute average best lambda
avg_best_lambda <- mean(best_lambdas)

# Train final model
final_model <- glmnet(X_train, y_train, alpha = alpha_value, 
                      family = "binomial", lambda = avg_best_lambda)

# Predict on test data
predictions <- predict(final_model, X_test, type = "response")

# Create ROC curve and calculate AUROC
roc_obj <- roc(y_test, as.numeric(predictions))
auc_value <- auc(roc_obj)
ci_roc <- ci.auc(roc_obj)

# Calculate confidence intervals
ci_se <- ci.se(roc_obj, specificities = seq(0, 1, length.out = 200))
ci_df <- data.frame(
  Specificity = as.numeric(rownames(ci_se)),
  Sensitivity_lower = ci_se[, "2.5%"],
  Sensitivity = ci_se[, "50%"],
  Sensitivity_upper = ci_se[, "97.5%"]
)

# Create ROC plot
pdf("roc_curve.pdf", width = 4, height = 4)
roc_plot <- ggplot() +
  geom_ribbon(data = ci_df, 
              aes(x = 1 - Specificity, 
                  ymin = Sensitivity_lower, 
                  ymax = Sensitivity_upper), 
              fill = "grey", alpha = 0.3) +
  geom_line(data = ci_df, 
            aes(x = 1 - Specificity, y = Sensitivity), 
            color = "blue") +
  ggtitle(paste("AUROC (95% CI) =",
                round(auc_value, 2),
                " (", 
                round(ci_roc[1], 2), ",", 
                round(ci_roc[3], 2), ")")) +
  xlab("1 - Specificity") +
  ylab("Sensitivity") +
  theme_classic(base_size = 8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black")
print(roc_plot)
dev.off()

# Extract and plot coefficients
coefficients <- as.data.frame(as.matrix(coef(final_model)))
selected_targets <- rownames(coefficients)[which(coefficients != 0)]
selected_targets <- selected_targets[selected_targets != "(Intercept)"]

coefficients <- coefficients[selected_targets, , drop = FALSE]
coefficients$targetName <- rownames(coefficients)
colnames(coefficients) <- c("Coefficient", "targetName")
coefficients$Category <- ifelse(coefficients$Coefficient < 0, 
                                "Increased probability of Group1", 
                                "Increased probability of Group2")

# Create coefficient plot
pdf("coefficients_plot.pdf", width = 8, height = 6)
bar_plot <- ggplot(coefficients, 
                   aes(x = reorder(targetName, Coefficient), 
                       y = Coefficient, 
                       fill = Category)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("Increased probability of Group1" = "#70D2D7", 
                               "Increased probability of Group2" = "#FBA09A")) +
  theme_classic(base_size = 12) +
  xlab("Target") +
  ylab("Elastic Net Coefficient") +
  ggtitle("Targets Multivariately Discriminating Group1 vs. Group2") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 12), 
        plot.margin = margin(t = 30, r = 30, b = 30, l = 30)) +
  labs(fill = NULL)
print(bar_plot)
dev.off()

# Save results
saveRDS(final_model, "final_model.rds")
saveRDS(auc_value, "auc_value.rds")
saveRDS(coefficients, "model_coefficients.rds")

# Print information for debugging
cat("Model saved to: final_model.rds\n")
cat("AUC value saved to: auc_value.rds\n")
cat("Coefficients saved to: model_coefficients.rds\n")
cat("ROC curve saved to: roc_curve.pdf\n")
cat("Coefficients plot saved to: coefficients_plot.pdf\n")
cat("Batch distribution plot saved to: batch_distribution.pdf\n")
cat("Test set AUC value:", auc_value, "\n")
cat("95% CI:", round(ci_roc[1], 2), "-", round(ci_roc[3], 2), "\n")