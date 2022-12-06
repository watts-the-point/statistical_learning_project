library(tidyverse)
library(tidymodels)


load("Results/5v_cleandf.RData")



df %>% count(disposition) %>% mutate(prop = n/sum(n))

set.seed(2079)
split <- initial_split(df, prop = .9)

training <- training(split)
testing <- testing(split)

full_xgb_rec <- 
  recipe(disposition ~ ., data = training) %>% 
  step_dummy(all_nominal_predictors()) %>% 
  step_zv(all_predictors())

xgb_mod <- boost_tree() %>% 
  set_engine("xgboost") %>% 
  set_mode("classification") %>% 
  set_args(max_depth = tune(),
           nthread = 5,
           #eta in build_boost.R
           learn_rate = 0.3, 
           #nrounds in build_boost.R
           trees = 30,
           colsample_bylevel = 0.05)

full_xgb_wf <- workflow() %>% 
  add_model(xgb_mod) %>% 
  add_recipe(full_xgb_rec)

tune_result <- 
  full_xgb_wf %>% 
  tune_grid(
    folds,
    grid = data.frame(max_depth = c(15, 20, 25)),
    control = control_grid(save_pred = TRUE),
    metrics = metric_set(roc_auc)
)

tune_result %>% show_best(metric = "roc_auc")

full_xgb_best <- tune_result %>% select_best(metric = "roc_auc")

full_xgb_best

tune_result %>% collect_predictions()

tuned_auc <- tune_result %>% collect_predictions(parameters = full_xgb_best) %>% 
  roc_curve(disposition, .pred_Admit) %>% mutate(model = "XGBoost Full")

full_xgb_fit <- full_xgb_wf %>% fit(data = training)

full_xgb_training_pred <- 
  predict(full_xgb_fit, training) %>% 
  bind_cols(predict(full_xgb_fit, training, type = "prob")) %>% 
  # Add the true outcome data back in
  bind_cols(training %>% 
              select(disposition))

roc_auc(full_xgb_training_pred, truth = disposition, .pred_Admit)

accuracy(full_xgb_training_pred, truth = disposition, .pred_class)

folds <- training %>% vfold_cv(v = 5)

cv_full_xgb_fit <- full_xgb_wf %>% fit_resamples(folds)

collect_metrics(cv_full_xgb_fit)

full_xgb_fit %>% extract_fit_parsnip() %>% vip::vip(num_features = 100)
