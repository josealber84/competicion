# XGBoost optimized model :)

# Load libraries
library(readr)
library(xgboost)
library(dplyr)
library(magrittr)
library(lubridate)
library(caret)
library(testthat)
library(AUC)

# Seed
set.seed(22)

# Read data
cat("reading the train and test data\n")
train <- read_csv("./data/train.csv")
test  <- read_csv("./data/test.csv")

# Divide predictors and objective
train.predictors <- train %>% select(-QuoteConversion_Flag)
train.objective <- train %>% select(QuoteConversion_Flag)
rm(train)
test.predictors <- test
rm(test)
gc()





# Convert all data to numeric
## Take all numeric columns
train.numeric <- train.predictors %>% select(which(sapply(., is.numeric)))
test.numeric <- test.predictors %>% select(which(sapply(., is.numeric)))

## Take non-numeric columns
train.other <- 
  train.predictors %>% select(which(sapply(., function(x) !is.numeric(x))))
test.other <- 
  test.predictors %>% select(which(sapply(., function(x) !is.numeric(x))))

## Divide Original_Quote_Date in day, year, month, weekday
train.dates <- ymd(train.other$Original_Quote_Date)
train.numeric$day <- day(train.dates)
train.numeric$month <- month(train.dates)
train.numeric$year <- year(train.dates)
train.numeric$weekday <- wday(train.dates)
train.other$Original_Quote_Date <- NULL
test.dates <- ymd(test.other$Original_Quote_Date)
test.numeric$day <- day(test.dates)
test.numeric$month <- month(test.dates)
test.numeric$year <- year(test.dates)
test.numeric$weekday <- wday(test.dates)
test.other$Original_Quote_Date <- NULL
rm(train.dates, test.dates)
gc()

## Convert everything else from charater to factor to integer
train.other.2 <- lapply(train.other, function(x) as.integer(as.factor(x)))
test.other.2 <- lapply(test.other, function(x) as.integer(as.factor(x)))
rm(train.other, test.other)
gc()

## Join
train.numeric %<>% bind_cols(train.other.2)
test.numeric %<>% bind_cols(test.other.2)
rm(train.other.2, test.other.2)
rm(train.predictors, test.predictors)
gc()



# Remove constant columns
train.numeric$PropertyField6 <- NULL
train.numeric$GeographicField10A <- NULL
test.numeric$PropertyField6 <- NULL
test.numeric$GeographicField10A <- NULL

# Remove QuoteNumber
train.numeric$QuoteNumber <- NULL
test.numeric$QuoteNumber <- NULL



# Conver to matrix
train.matrix <- as.matrix(train.numeric)
test.matrix <- as.matrix(test.numeric)
train.objective <- as.matrix(train.objective)
rm(train.numeric)
rm(test.numeric)
gc()


# Fill missing values with the median
## Remove columns with more than 50% NAs
pb <- progress_estimated(ncol(train.matrix))
removed.predictors <- c()
for(col in 1:ncol(train.matrix)){
  pb$tick()$print()
  if(sum(is.na(train.matrix[, col])) > 0.5*length(train.matrix[, col])){
    removed.predictors <- c(removed.predictors, col)
  }
}
cat("Removed predictors: ", removed.predictors, fill = T)
if(length(removed.predictors) > 0){
  train.matrix <- train.matrix[, -removed.predictors]
  test.matrix <- test.matrix[, -removed.predictors]
}
expect_equal(ncol(train.matrix), ncol(test.matrix))

## Change NAs by the median value in the column
pb <- progress_estimated(ncol(train.matrix))
median.values <- data.frame(column = c(), value = c())
for(col in 1:ncol(train.matrix)){
  pb$tick()$print()
  median.values[col, 1] <- col
  median.values[col, 2] <- median(train.matrix[, col], na.rm = T)
  train.matrix[, col][is.na(train.matrix[, col])] <- median.values[col, 2]
  test.matrix[, col][is.na(test.matrix[, col])] <- median.values[col, 2]
}
gc()





# Center and scale
pb <- progress_estimated(ncol(train.matrix))
mean.values <- data.frame(column = c(), value = c())
sd.values <- data.frame(column = c(), value = c())
for(col in 1:ncol(train.matrix)){
  pb$tick()$print()
  mean.values[col, 1] <- col
  mean.values[col, 2] <- mean(train.matrix[, col])
  sd.values[col, 1] <- col
  sd.values[col, 2] <- sd(train.matrix[, col])
  train.matrix[, col] <- train.matrix[, col] - mean.values[col, 2]
  train.matrix[, col] <- train.matrix[, col] / sd.values[col, 2]
  test.matrix[, col] <- test.matrix[, col] - mean.values[col, 2]
  test.matrix[, col] <- test.matrix[, col] / sd.values[col, 2]
}
gc()


# MODEL

  
xgb_params_1 = list(
  objective = "binary:logistic",                                               # binary classification
  eta = eta,                                                                  # learning rate
  max.depth = 15,                                                               # max tree depth
  eval_metric = "auc"                                                        # evaluation/loss metric
)

set.seed(22)

# cross-validate xgboost to get the accurate measure of error
xgb_cv_1 = xgb.cv(params = xgb_params_1,
                  data = train.matrix,
                  label = train.objective,
                  nrounds = 300, 
                  nfold = 10,                                                  # return the prediction using the final model 
                  showsd = TRUE,                                               # standard deviation of loss across folds
                  stratified = TRUE,                                           # sample is unbalanced; use stratified sampling
                  verbose = TRUE,
                  print.every.n = 1, 
                  early.stop.round = 10
)


save(results, file = "results.Rdata")
