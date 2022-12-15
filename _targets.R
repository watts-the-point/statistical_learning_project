# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
# library(tarchetypes) # Load other packages as needed. # nolint

# Set target options:
tar_option_set(
  packages = c("tibble", "tidyverse", "caret", "tidymodels"), # packages that your targets need to run
  format = "rds", # default storage format
  # Set other options as needed.
  memory = "transient",
  garbage_collection = TRUE
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# tar_make_future() configuration (okay to leave alone):
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to allow use_targets() to configure tar_make_future() options.

# Run the R scripts in the R/ folder with your custom functions:
tar_source("R/functions.R")
# source("other_functions.R") # Source other scripts as needed. # nolint

# Replace the target list below with your own:
list(
  tar_target(indices,
             read_indices()),
  tar_target(test_indices,
             indices[[1]]$i_test),
  tar_target(df,
             read_data()),
  tar_target(processed,
               recipe(disposition ~ ., data = training) %>% 
               step_dummy(all_nominal_predictors()) %>% 
               prep() %>% 
               bake(df)),
  tar_target(predictors,
             processed %>% select(-disposition)),
  tar_target(outcome,
             df$disposition),
  tar_target(test_x,
             predictors[test_indices,]),
  tar_target(test_y,
             outcome[test_indices]),
  tar_target(train_x,
             predictors[c(indices[[1]]$i_dev, indices[[1]]$i_train),]),
  tar_target(train_y,
             outcome[c(indices[[1]]$i_dev, indices[[1]]$i_train)]),
#create a list of targets for the caret model and tidymodels model separately
#
# Caret
  tar_target(caret_folds,
             list(indices[[1]]$i_dev,
                  indices[[2]]$i_dev,
                  indices[[3]]$i_dev,
                  indices[[4]]$i_dev,
                  indices[[5]]$i_dev)),
  tar_target(caret_control,
             trainControl(method = "cv",
                          index = caret_folds,
                          classProbs = TRUE,
                          savePredictions = TRUE,
                          summaryFunction = prSummary,
                          verboseIter = TRUE)),
  tar_target(xgb_grid,
             expand.grid(
               maxdepth = c(15, 20, 25),
               eta = 0.3,
               nthread = 5,
               nrounds = 30,
               colsample_bylevel = 0.05)),
  tar_target(caret_fit,
             train(train_x,
                   train_y, 
                   method = "xgbTree",
                   control = caret_control,
                   metric = "AUC",
                   tunegrid = xgb_grid
                   )),
  #
  #Tidymodels
  tar_target(index_list,
             lapply(indices, 
                    function(x){
                      list(analysis = as.integer(x$i_train), 
                           assessment = as.integer(x$i_dev))
                      })),
  tar_target(splits,
             lapply(index_list, make_splits, data = df)),
  tar_target(rset_folds,
             manual_rset(splits, index_list)),
  tar_target(tidy_control,
             control_grid(verbose = TRUE,
                          save_pred = TRUE)),
  tar_target(model,
             boost_tree() %>% 
               set_engine("xgboost") %>% 
               set_mode("classification") %>% 
               set_args(nthread = 5, 
                        tree_depth = tune(),
                        eta = 0.3, 
                        trees = 30,
                        colsample_bylevel = 0.05)),
  tar_target(workflow,
             workflow() %>% 
               add_variables(outcomes = outcome, predictors = predictors) %>% 
               add_model(model)),
  tar_target(fit_res,
             tune_grid(workflow, 
                       resamples = rset_folds, 
                       grid = c(15, 20, 25),
                       control = tidy_control,
                       metrics = metric_set("roc_auc")))
)
