library(tidyverse)
library(tidymodels)
library(doMC)

registerDoMC(5)

load("Results/5v_cleandf.RData")

df %>% count(disposition) %>% mutate(prop = n/sum(n))

set.seed(2079)
split <- initial_split(df, prop = .9)

training <- training(split)
testing <- testing(split)

full_xgb_rec <- 
  recipe(disposition ~ ., data = training) %>% 
  step_dummy(all_nominal())

full_xgb_rec %>% prep()

cv_set <- vfold_cv(training, v = 5)

xgb_mod <- boost_tree() %>% 
  set_engine("xgboost") %>% 
  set_mode("classification") %>% 
  set_args(nthread = 5, 
           eta = 0.3, 
           nrounds = 30,
           colsample_bylevel = 0.05)

xgb_mod %>% fit(disposition ~ ., training)

xgb_wf <- workflow() %>% 
  add_model(xgb_mod) %>% 
  add_recipe(full_xgb_rec)

xgb_wf %>% fit(data = training)
