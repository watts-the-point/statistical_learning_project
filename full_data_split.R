library(tidyverse)
library(tidymodels)

#load the data
load("Results/5v_cleandf.RData")

#check proportions of data
df %>% count(disposition) %>% mutate(prop = n/sum(n))

#set seed and split data into testing and training with 5 folds
set.seed(2079)
split <- initial_split(df, prop = .9)
rm(df)

#save 5-fold CV set of training data
train <- training(split)
test <-  testing(split)

rm(split)

save(train, file = "full_training.RData")
save(test, file = "full_testing.RData")

rm(test)

val_set <- train %>% 
  vfold_cv(v = 9) %>% 
  slice(1:5)

val_set <- manual_rset(val_set$splits, val_set$id)

rm(train)

save(val_set, file = "full_folds.RData")

rm(val_set)
