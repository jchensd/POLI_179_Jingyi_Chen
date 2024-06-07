#---------------------------------
# Estimate glove model
#---------------------------------
#load package
library(text2vec)
library(parallel)
library(data.table)

#set my working directory
setwd("/Users/jingyichen/Library/Mobile Documents/com~apple~CloudDocs/POLI 179/POLI_179_Jingyi_Chen/Data & Models")

#construct the feature co-occurrence matrix for the toks_ALLspeeches object
toks_fcm_ALLspeeches <- fcm(toks_ALLspeeches, context = "window", window = 6, count = "frequency", tri = FALSE) 

#estimate glove model 
glove_ALLSpeeches <- GlobalVectors$new(rank = 300, 
                                       x_max = 10,
                                       learning_rate = 0.05)
wv_main_ALL <- glove_ALLSpeeches$fit_transform(toks_fcm_ALLspeeches, n_iter = 100,
                                               convergence_tol = 1e-4, 
                                               n_threads = parallel::detectCores(), shuffle_seed = 2024L) 
wv_context_ALL <- glove_ALLSpeeches$components
local_glove_ALL <- wv_main_ALL + t(wv_context_ALL) 

#Save the trained glove embedding to a RDS file.
saveRDS(local_glove_ALL, "local_glove_ALL.rds")

#qualitative check the nearest neighbors to ensure they make sense.
find_nns(local_glove_ALL['ruleoflaw', ], pre_trained = local_glove_ALL, N = 5, candidates = features_ALLspeeches)

#compute the transform matrix (A Matrix)
local_transform_ALL <- compute_transform(x = toks_fcm_ALLspeeches, pre_trained = local_glove_ALL, weighting = "log")

#Save the transform matrix to a RDS file.
saveRDS(local_transform_ALL, "local_transform_ALL.rds")
#-----------------------------------------------