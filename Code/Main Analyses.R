
#This code performs ALC Embedding and conText Regression analyses to:

#1. compare how China and the United States conceptualize the rule of law in the United Nations Security Council (UNSC).

#2. assess the correlation between the Democracy Index and the interpretation and framing of the rule of law across all countries in the UNSC.

#set my working directory
setwd("~/Library/Mobile Documents/com~apple~CloudDocs/Past Courses/POLI 179/POLI_179_Jingyi_Chen/Data & Models")

#clear all previous objects.
#rm(list = ls())

#load the filtered dataset.
filtered_ALLspeeches <- readRDS("filtered_ALLspeeches.rds")

#---------------------------------
# Text pre-processing
#---------------------------------
#load packages
library(conText)
library(quanteda)
library(tidyverse)

#create a corpus of texts.
corpus_ALLspeeches <- corpus(filtered_ALLspeeches, text_field = "text")
#adding 'doc_id' as a separate document variable for future extraction of original texts.
docvars(corpus_ALLspeeches, "doc_id") <- filtered_ALLspeeches$doc_id
#verify if 'doc_id' is present in the document variables.
docvars(corpus_ALLspeeches)

#tokenize corpus removing semantically uninformative elements.
toks_ALLspeeches <- tokens(corpus_ALLspeeches, remove_punct=T, remove_symbols=T, remove_numbers=T, remove_separators=T)
toks_ALLspeeches <- tokens_tolower(toks_ALLspeeches)
#clean out stopwords and words with 2 or fewer characters.
toks_ALLspeeches <- tokens_select(toks_ALLspeeches, pattern = stopwords("en"), selection = "remove", min_nchar=3)
#only use features that appear at least 5 times in the corpus.
features_ALLspeeches <- dfm(toks_ALLspeeches, verbose = FALSE) %>% 
  dfm_trim(min_termfreq = 5) %>% featnames()
#leave the pads so that non-adjacent words will not become adjacent.
toks_ALLspeeches <- tokens_select(toks_ALLspeeches, features_ALLspeeches, padding = TRUE)

#build a tokenized corpus of contexts surrounding the target term "ruleoflaw".
#the window size is 5, meaning 5 words before and after each instance of "ruleoflaw" are extracted.
ruleoflaw_toks <- tokens_context(x = toks_ALLspeeches, pattern = "ruleoflaw", window = 5L)
#build document-feature matrix.
ruleoflaw_dfm <- dfm(ruleoflaw_toks)
#construct the feature co-occurrence matrix for the toks_ALLspeeches object
toks_fcm_ALLspeeches <- fcm(toks_ALLspeeches, context = "window", window = 6, count = "frequency", tri = FALSE) 

#---------------------------------
# Estimate the GloVe model using the full UNSC speech dataset. 

# The GloVe word vectors will be utilized later to create context-specific embeddings through the methods of ALC Embedding and conText Regression
#---------------------------------
#load package
library(parallel)
library(data.table)
library(text2vec)

#estimate GloVe model. 
#word vectors of 300 dimensions will be computed.
glove_ALLSpeeches <- GlobalVectors$new(rank = 300, 
                                       x_max = 10,
                                       learning_rate = 0.05)
#fit the GloVe model to the co-occurrence matrix created for the corpus of contextual words surrounding "ruleoflaw" in the UNSC speeches.
wv_main_ALL <- glove_ALLSpeeches$fit_transform(toks_fcm_ALLspeeches, n_iter = 100,
                                               convergence_tol = 1e-4, 
                                               n_threads = parallel::detectCores(), shuffle_seed = 2024L) 
#extract the context vectors from the model
wv_context_ALL <- glove_ALLSpeeches$components
#combine main and context vectors to create the final GloVe word embeddings
local_glove_ALL <- wv_main_ALL + t(wv_context_ALL) 

#Save the trained GloVe embedding to a RDS file.
saveRDS(local_glove_ALL, "local_glove_ALL.rds")

#conduct a qualitative check of the nearest neighbors for "ruleoflaw" to ensure they make sense.
find_nns(local_glove_ALL['ruleoflaw', ], pre_trained = local_glove_ALL, N = 5, candidates = features_ALLspeeches)

#compute the transform matrix (A Matrix)
local_transform_ALL <- compute_transform(x = toks_fcm_ALLspeeches, pre_trained = local_glove_ALL, weighting = "log")

#Save the transform matrix to a RDS file.
saveRDS(local_transform_ALL, "local_transform_ALL.rds")

#---------------------------------
# ALC Embedding
#---------------------------------
#load the saved models
local_glove_ALL <- readRDS("local_glove_ALL.rds")
local_transform_ALL <- readRDS("local_transform_ALL.rds")

#create document-embedding matrix using the locally trained GloVe embeddings and transformation matrix
RofL_dem_local_glove_ALL <- dem(x = ruleoflaw_dfm, pre_trained = local_glove_ALL, transform = TRUE, transform_matrix = local_transform_ALL, verbose = TRUE)

#the ALC embeddings of "ruleoflaw" for all countries and for each country separately are computed using the GloVe embeddings of words surrounding "ruleoflaw".
#take the column average to get a single embedding of "ruleoflaw" for speeches by all countries.
RofL_wv_local_glove_ALL <- colMeans(RofL_dem_local_glove_ALL)
#find nearest neighbors for overall "ruleoflaw" embedding.
nn_features_overall <- as.data.frame(nns(RofL_wv_local_glove_ALL, pre_trained = local_glove_ALL, N = 10, candidates = RofL_dem_local_glove_ALL@features, as_list = FALSE))

#average within each country to get "ruleoflaw" embeddings for each country.
ruleoflaw_wv_country_local_ALL <- dem_group(RofL_dem_local_glove_ALL, groups = RofL_dem_local_glove_ALL@docvars$country)
#check the dimensions of the embeddings.
dim(ruleoflaw_wv_country_local_ALL)

#find nearest neighbors of "ruleoflaw" by country.
ruleoflaw_nns_local_ALL <- nns(ruleoflaw_wv_country_local_ALL, pre_trained = local_glove_ALL, N = 20, candidates = ruleoflaw_wv_country_local_ALL@features, as_list = TRUE)

#extract nearest neighbors for China and the US.
nn_features_China <- as.data.frame(ruleoflaw_nns_local_ALL[["China"]])
nn_features_US <- as.data.frame(ruleoflaw_nns_local_ALL[["United States Of America"]])

#compute the cosine similarity between each country's embedding and a specific set of features (stability, humanrights)
cos_similarity_stability <- cos_sim(ruleoflaw_wv_country_local_ALL, pre_trained = local_glove_ALL, features = c('stability'), as_list = FALSE) %>% 
  arrange(desc(value))
cos_similarity_humanrights <- cos_sim(ruleoflaw_wv_country_local_ALL, pre_trained = local_glove_ALL, features = c('humanrights'), as_list = FALSE) %>% 
  arrange(desc(value))

#compute the ratios of cosine similarity between each country's embedding and other terms.
#this helps identify terms that are most associated with the "ruleoflaw" ALC embedding of one country compared to that of another country.
nns_ratio_China_US <- as.data.frame(nns_ratio(x = ruleoflaw_wv_country_local_ALL[c("China", "United States Of America"), ], N = 16, numerator = "China", candidates = ruleoflaw_wv_country_local_ALL@features, pre_trained = local_glove_ALL, verbose = FALSE))

#compute the cosine similarity between each country's embedding and a set of tokenized contextual words surrounding "ruleoflaw" in the original speeches
ruleoflaw_ncs_local_ALL <- ncs(x = ruleoflaw_wv_country_local_ALL, contexts_dem = RofL_dem_local_glove_ALL, contexts = ruleoflaw_toks, N = 5, as_list = TRUE)
#nearest contexts to US and China embeddings of "ruleoflaw"
ruleoflaw_ncs_local_ALL[["United States Of America"]]$context
ruleoflaw_ncs_local_ALL[["China"]]$context

#find the original UNSC speeches containing the nearest contexts
#convert each list of contextual tokens into a single string separated by single spaces and create a dataframe
context_df <- data.frame(context = sapply(ruleoflaw_toks, function(tokens) {
  paste(tokens, collapse = " ")
}))
#extract the doc_id values and add as a new column to the contextual token dataframe. 
context_df$doc_id <- ruleoflaw_dfm@docvars[["doc_id"]]
#match the nearest contextual tokens with the tokens in "context_df" to identify its doc_id.
#using the doc_id, print out the country, contextual tokens, and the original texts of the nearest contextual tokens
for (tokens in ruleoflaw_ncs_local_ALL[["China"]]$context){
  doc_id_context = context_df$doc_id[context_df$context == tokens]
  print(doc_id_context)
  print(filtered_ALLspeeches$country[filtered_ALLspeeches$doc_id == doc_id_context])
  print(context_df$context[context_df$context == tokens])
  print(filtered_ALLspeeches$text[filtered_ALLspeeches$doc_id == doc_id_context])
}

#---------------------------------
# conText Embedding Regression
#---------------------------------
#load the dataset merging democracy indexs and U.N. Security Council speeches
merged_countries_democracy_index <- readRDS("merged_countries_democracy_index.rds")

#Text pre-processing------------------------------------------------------------
#create a corpus of texts.
corpus_merged_countries_dem_index <- corpus(merged_countries_democracy_index, text_field = "text")

#tokenize corpus removing semantically uninformative elements
toks_merged_countries_dem_index <- tokens(corpus_merged_countries_dem_index, remove_punct=T, remove_symbols=T, remove_numbers=T, remove_separators=T)
toks_merged_countries_dem_index <- tokens_tolower(toks_merged_countries_dem_index)
#clean out stopwords and words with 2 or fewer characters
toks_merged_countries_dem_index <- tokens_select(toks_merged_countries_dem_index, pattern = stopwords("en"), selection = "remove", min_nchar=3)
toks_merged_countries_dem_index_stemmed <- tokens_wordstem(toks_merged_countries_dem_index)
#only use features that appear at least 5 times in the corpus
features_merged_countries_dem_index <- dfm(toks_merged_countries_dem_index, verbose = FALSE) %>% 
  dfm_trim(min_termfreq = 5) %>% featnames()
#leave the pads so that non-adjacent words will not become adjacent
toks_merged_countries_features_dem_index <- tokens_select(toks_merged_countries_dem_index, features_merged_countries_dem_index, padding = TRUE)

#set a seed
set.seed(2024L)
#regress the embeddings over democracy index
democracy_index_model <- conText(formula = "ruleoflaw" ~ Democracy.score,
                           data = toks_merged_countries_features_dem_index,
                           pre_trained = local_glove_ALL,
                           transform = TRUE, transform_matrix = local_transform_ALL,
                           jackknife = TRUE, confidence_level = 0.95,
                           permute = TRUE, num_permutations = 100,
                           window = 6, case_insensitive = TRUE,
                           verbose = FALSE)

#calculate percentiles of the democracy index
percentiles_dem_index <- quantile(docvars(corpus_merged_countries_dem_index)$Democracy.score, probs = seq(0.05,0.95,0.05))
#compute conText regression embeddings of "ruleoflaw" for each democracy index percentile
percentile_wvs_dem_index <- lapply(percentiles_dem_index, function(i) democracy_index_model["(Intercept)",] + i*democracy_index_model["Democracy.score",]) %>% do.call(rbind,.) 

#compute cosine similarities between percentile embeddings and selected features
percentile_sim_dem_index <- cos_sim(x = percentile_wvs_dem_index, pre_trained = local_glove_ALL, features = c("support", "illegal", "stability", "humanrights", "justice", "security", "accountability"), as_list = TRUE)

#find nearest neighbors of the "ruleoflaw" embeddings for each percentile
nearest_neighbors_dem_index <- nns(rbind(percentile_wvs_dem_index), N = 15, pre_trained = local_glove_ALL, candidates = democracy_index_model@features)

#compute the ratios of cosine similarity between 95th and 5th percentile embedding and other terms.
#this helps identify terms that are most associated with the "ruleoflaw" embedding of countries with high Democracy Index compared to that of countries with low index
nns_ratio_democracy_index <- nns_ratio(x = percentile_wvs_dem_index[c("95%", "5%"), ], N = 100, numerator = "95%", candidates = democracy_index_model@features, pre_trained = local_glove_ALL, verbose = FALSE)
