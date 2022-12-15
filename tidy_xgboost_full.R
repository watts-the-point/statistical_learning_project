library(tidyverse)
library(tidymodels)
<<<<<<< HEAD
library(doMC)

registerDoMC(5)

load("Results/5v_cleandf.RData")

df %>% count(disposition) %>% mutate(prop = n/sum(n))

df <- df %>% mutate(disposition = factor(disposition))

set.seed(3883)
=======


load("Results/5v_cleandf.RData")



df %>% count(disposition) %>% mutate(prop = n/sum(n))

set.seed(2079)
>>>>>>> 45b5a296d760ad70836199da21fd0ab511368063
split <- initial_split(df, prop = .9)

training <- training(split)
testing <- testing(split)

<<<<<<< HEAD


full_xgb_rec <- 
  recipe(disposition ~ ., data = training) %>% 
  step_dummy(all_nominal_predictors())

full_xgb_rec %>% prep()

indexes <- list(
  list(analysis = indices[[1]]$i_train %>% as.integer, 
       assessment = indices[[1]]$i_dev %>% as.integer),
  list(analysis = indices[[2]]$i_train %>% as.integer, 
       assessment = indices[[2]]$i_dev %>% as.integer),
  list(analysis = indices[[3]]$i_train %>% as.integer, 
       assessment = indices[[3]]$i_dev %>% as.integer),
  list(analysis = indices[[4]]$i_train %>% as.integer, 
       assessment = indices[[4]]$i_dev %>% as.integer),
  list(analysis = indices[[5]]$i_train %>% as.integer, 
       assessment = indices[[5]]$i_dev %>% as.integer)
) 

splitsss <- lapply(indexes, make_splits, data = df)

cv_set <- vfold_cv(training, v = 9) %>% 
  slice(1:5)
cv_set <- manual_rset(splits = cv_set$splits, 
                   ids = cv_set$id)
=======
full_xgb_rec <- 
  recipe(disposition ~ ., data = training) %>% 
  step_dummy(all_nominal_predictors()) %>% 
  step_zv(all_predictors())

full_xgb_rec %>% prep()

cv_set <- vfold_cv(training, v = 5)
>>>>>>> 45b5a296d760ad70836199da21fd0ab511368063

xgb_mod <- boost_tree() %>% 
  set_engine("xgboost") %>% 
  set_mode("classification") %>% 
<<<<<<< HEAD
  set_args(nthread = 5, 
           eta = 0.3, 
           trees = 30,
           colsample_bylevel = 0.05)

xgb_mod %>% fit(disposition ~ ., training)

=======
  set_args(nthread = 5,
           #eta in build_boost.R
           learn_rate = 0.3, 
           #nrounds in build_boost.R
           trees = 30,
           colsample_bylevel = 0.05)

>>>>>>> 45b5a296d760ad70836199da21fd0ab511368063
xgb_wf <- workflow() %>% 
  add_model(xgb_mod) %>% 
  add_recipe(full_xgb_rec)

<<<<<<< HEAD
control <- control_resamples(verbose = T, save_pred = T)

xgb_fit <- xgb_wf %>% 
  fit_resamples(data = training,
                resamples = cv_set,
                control = control,
                metrics = metric_set(accuracy, roc_auc))
=======
full_xgb_fit <- xgb_wf %>% fit(data = training)

>>>>>>> 45b5a296d760ad70836199da21fd0ab511368063
