read_data <- function(){
  load("Results/5v_cleandf.RData")
  df
}

read_indices <- function(){
  load("Results/5v_indeces_list.RData")
  indeces_list
}

#taken from 21_makematrix.R
makematrix <- function(df, sparse = T) {
  library(Matrix)
  # recode our response
  df$disposition <- as.numeric(df$disposition == 'Admit')
  response <- df$disposition
  df <- select(df,-disposition)
  
  #dummify categorical variables and encode into matrix
  dmy <- dummyVars(" ~ .", data = df)
  if (sparse) {
    df <- Matrix(predict(dmy, newdata = df), sparse = T)
  } else {
    df <- predict(dmy, newdata = df)
  }
  
  list(y = response, x = df)
}

