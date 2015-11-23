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



# Save clean data
save.image("imagen3.RData")



# Train the model
## xgboost(data = NULL, label = NULL, missing = NULL, params = list(),
## nrounds, verbose = 1, print.every.n = 1L, early.stop.round = NULL,
## maximize = NULL, ...)

## Create cv partitions
n.folds <- 10
n.reps <- 2

cv.folds <- createFolds(y = train.objective,
                        k = n.folds,
                        list = TRUE)
results <- data.frame(parameter = c(), mean.error = c(), mean.sd = c())
nrounds.values <- c(30, 50, 70)
for(nrounds in nrounds.values){
    
    cat("Trying models with nrounds = ", nrounds, fill = T)
    rep.results <- data.frame(parameter = rep(0, n.reps), 
                              mean.error = rep(0, n.reps), 
                              mean.sd = rep(0, nreps))
    
    for(rep in 1:n.reps){
        
        cat("Repetition ", rep, fill = T)
        fold.results <- 
            data.frame(parameter = rep(0, length(cv.folds)), 
                       auc = rep(0, length(cv.folds)))
        fold.count <- 0
        
        for(fold in cv.folds){
            
            fold.count <- fold.count + 1
            cat("Fold ", fold.count, fill = TRUE)
            train <- train.matrix[-fold, ]
            labels.train <- train.objective[-fold]
            labels.test <- train.objective[fold]
            test <- train.matrix[fold, ]
            model <- xgboost(data = train,
                             label = labels.train,
                             objective = "binary:logistic",
                             eta = 0.01,
                             max.depth = 7,
                             nthread = 4,
                             nrounds = nrounds,
                             verbose = 1,
                             print.every.n = 1,
                             early.stop.round = 10,
                             eval_metric = "auc")
            prediction <- predict(model, test)
            expect_equal(length(prediction), length(labels.test))
            roc.curve <- roc(prediction, as.factor(labels.test))
            auc.roc <- auc(roc.curve)
            fold.results$parameter[fold.count] <- nrounds
            fold.results$auc[fold.count] <- auc.roc
            cat("Results fold - auc = ", auc.roc, fill = T)
            gc()
        }
        
        rep.results %<>% 
            rbind(eta, mean(fold.results$auc), sd(fold.results$auc))
        cat("Results repetition - \n auc(mean) = ", mean(fold.results$auc),
            "\n auc(sd) = ", sd(fold.results$auc), fill = T)
        
    }
}

gc()
