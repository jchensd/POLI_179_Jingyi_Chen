#set my working directory
setwd("/Users/jingyichen/Library/Mobile Documents/com~apple~CloudDocs/POLI 179/POLI_179_Jingyi_Chen/Data & Models")

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
# Adding 'doc_id' as a separate document variable
docvars(corpus_ALLspeeches, "doc_id") <- filtered_ALLspeeches$doc_id
# Verify if 'doc_id' is present in the document variables
docvars(corpus_ALLspeeches)

#tokenize corpus removing unnecessary (i.e. semantically uninformative) elements
toks_ALLspeeches <- tokens(corpus_ALLspeeches, remove_punct=T, remove_symbols=T, remove_numbers=T, remove_separators=T)
toks_ALLspeeches <- tokens_tolower(toks_ALLspeeches)

#clean out stopwords and words with 2 or fewer characters
toks_ALLspeeches <- tokens_select(toks_ALLspeeches, pattern = stopwords("en"), selection = "remove", min_nchar=3)

#only use features that appear at least 5 times in the corpus
features_ALLspeeches <- dfm(toks_ALLspeeches, verbose = FALSE) %>% 
  dfm_trim(min_termfreq = 5) %>% featnames()
#leave the pads so that non-adjacent words will not become adjacent
toks_ALLspeeches <- tokens_select(toks_ALLspeeches, features_ALLspeeches, padding = TRUE)
#build a tokenized corpus of contexts surrounding the target term "ruleoflaw"
ruleoflaw_toks <- tokens_context(x = toks_ALLspeeches, pattern = "ruleoflaw", window = 6L)

#build document-feature matrix
ruleoflaw_dfm <- dfm(ruleoflaw_toks)


#load package
library(parallel)
library(data.table)
#construct the feature co-occurrence matrix for the toks_ALLspeeches object
toks_fcm_ALLspeeches <- fcm(toks_ALLspeeches, context = "window", window = 6, count = "frequency", tri = FALSE) 


#load the saved models
local_glove_ALL <- readRDS("local_glove_ALL.rds")
#local_transform_ALL <- readRDS("local_transform_ALL.rds")
local_glove_ALL <- zh_embeddings
#compute the transform matrix (A Matrix)
local_transform_ALL <- compute_transform(x = toks_fcm_ALLspeeches, pre_trained = local_glove_ALL, weighting = "log")


#create document-embedding matrix using our locally trained GloVe embeddings and transformation matrix
RofL_dem_local_glove_ALL <- dem(x = ruleoflaw_dfm, pre_trained = local_glove_ALL, transform = TRUE, transform_matrix = local_transform_ALL, verbose = TRUE)


# take the column average to get a single "corpus-wide" embedding
RofL_wv_local_glove_ALL <- colMeans(RofL_dem_local_glove_ALL)

# find nearest neighbors for overall ruleoflaw embedding
nn_features_overall <- as.data.frame(nns(RofL_wv_local_glove_ALL, pre_trained = local_glove_ALL, N = 10, candidates = RofL_dem_local_glove_ALL@features, as_list = FALSE))


#to get group-specific embeddings, average within country
ruleoflaw_wv_country_local_ALL <- dem_group(RofL_dem_local_glove_ALL, groups = RofL_dem_local_glove_ALL@docvars$country)
dim(ruleoflaw_wv_country_local_ALL)


#find nearest neighbors by country
#if setting as_list = FALSE combines each group's results into a single tibble (useful for joint plotting)
ruleoflaw_nns_local_ALL <- nns(ruleoflaw_wv_country_local_ALL, pre_trained = local_glove_ALL, N = 10, candidates = ruleoflaw_wv_country_local_ALL@features, as_list = TRUE)

#check out results for countries
nn_features_China <- as.data.frame(ruleoflaw_nns_local_ALL[["China"]])
nn_features_US <- as.data.frame(ruleoflaw_nns_local_ALL[["United States Of America"]])

#compute the cosine similarity between each country's embedding and a specific set of features
cos_similarity_stability <- cos_sim(ruleoflaw_wv_country_local_ALL, pre_trained = local_glove_ALL, features = c('stability'), as_list = FALSE) %>% 
  arrange(desc(value))
cos_similarity_humanrights <- cos_sim(ruleoflaw_wv_country_local_ALL, pre_trained = local_glove_ALL, features = c('humanrights'), as_list = FALSE) %>% 
  arrange(desc(value))

#compute the cosine similarity between each country's embedding and a specific set of features
nns_ratio_China_US <- as.data.frame(nns_ratio(x = ruleoflaw_wv_country_local_ALL[c("China", "United States Of America"), ], N = 11, numerator = "China", candidates = ruleoflaw_wv_country_local_ALL@features, pre_trained = local_glove_ALL, verbose = FALSE))
nns_ratio(x = ruleoflaw_wv_country_local_ALL[c("United States Of America", "China"), ], N = 20, numerator = "United States Of America", candidates = ruleoflaw_wv_country_local_ALL@features, pre_trained = local_glove_ALL, verbose = FALSE)

#compute the cosine similarity between each country's embedding and a set of tokenized contexts
ruleoflaw_ncs_local_ALL <- ncs(x = ruleoflaw_wv_country_local_ALL, contexts_dem = RofL_dem_local_glove_ALL, contexts = ruleoflaw_toks, N = 5, as_list = TRUE)


# nearest contexts to USA and China embedding of target term
# note, these may included contexts originating from Chinese and U.S. speakers
ruleoflaw_ncs_local_ALL[["United States Of America"]]
ruleoflaw_ncs_local_ALL[["China"]]$context
# Convert each list of tokens into a single space-separated string and create a dataframe

context_df <- data.frame(context = sapply(ruleoflaw_toks, function(tokens) {
  paste(tokens, collapse = " ")
}))

#Extract the doc_id values into a vector. Add this vector as a new column to context_df
context_df$doc_id <- ruleoflaw_dfm@docvars[["doc_id"]]

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
set.seed(2024L)

#load the data merging democracy indexs and U.N. Security Council speeches
merged_countries_democracy_index <- readRDS("merged_countries_democracy_index.rds")

#create a new variable "contain_ruleoflaw" that takes the value of 1 when the speech mention ruleoflaw and 0 when it doesn't.
merged_countries_democracy_index <- merged_countries_democracy_index %>%
  mutate(China = ifelse(grepl("China", country), 1, 0))
#merged_countries_democracy_index <- merged_countries_democracy_index %>% 
#  filter(China == 0)
#Text pre-processing------------------------------------------------------------
#-------------------------------------------------------------------------------
#create a corpus of texts.
corpus_merged_countries_dem_index <- corpus(merged_countries_democracy_index, text_field = "text")

#tokenize corpus removing unnecessary (i.e. semantically uninformative) elements
toks_merged_countries_dem_index <- tokens(corpus_merged_countries_dem_index, remove_punct=T, remove_symbols=T, remove_numbers=T, remove_separators=T)
toks_merged_countries_dem_index <- tokens_tolower(toks_merged_countries_dem_index)

#clean out stopwords and words with 2 or fewer characters
toks_merged_countries_dem_index <- tokens_select(toks_merged_countries_dem_index, pattern = stopwords("en"), selection = "remove", min_nchar=3)
toks_merged_countries_dem_index_stemmed <- tokens_wordstem(toks_merged_countries_dem_index)

#only use features that appear at least 5 times in the corpus
features_merged_countries_dem_index <- dfm(toks_merged_countries_dem_index, verbose = FALSE) %>% 
  dfm_trim(min_termfreq = 5) %>% featnames()
#dfm_merged_countries_dem_index <- dfm(toks_merged_countries_dem_index_stemmed) %>% 
#  dfm_trim(min_termfreq = 5)

# leave the pads so that non-adjacent words will not become adjacent
toks_merged_countries_features_dem_index <- tokens_select(toks_merged_countries_dem_index, features_merged_countries_dem_index, padding = TRUE)

#regress the embeddings over democracy index
democracy_index_model <- conText(formula = "ruleoflaw" ~ Democracy.score,
                           data = toks_merged_countries_features_dem_index,
                           pre_trained = local_glove_ALL,
                           transform = TRUE, transform_matrix = local_transform_ALL,
                           jackknife = TRUE, confidence_level = 0.95,
                           permute = TRUE, num_permutations = 100,
                           window = 6, case_insensitive = TRUE,
                           verbose = FALSE)

# look at percentiles of democracy index
percentiles_dem_index <- quantile(docvars(corpus_merged_countries_dem_index)$Democracy.score, probs = seq(0.05,0.95,0.05))
percentile_wvs_dem_index <- lapply(percentiles_dem_index, function(i) democracy_index_model["(Intercept)",] + i*democracy_index_model["Democracy.score",]) %>% do.call(rbind,.) 
percentile_sim_dem_index <- cos_sim(x = percentile_wvs_dem_index, pre_trained = local_glove_ALL, features = c("support", "illegal", "stability", "humanrights", "justice", "security", "accountability"), as_list = TRUE)
# nearest neighbors
nearest_neighbors_dem_index <- nns(rbind(percentile_wvs_dem_index), N = 15, pre_trained = local_glove_ALL, candidates = democracy_index_model@features)
nns_ratio_democracy_index <- nns_ratio(x = percentile_wvs_dem_index[c("95%", "5%"), ], N = 15, numerator = "95%", candidates = ruleoflaw_wv_country_local_ALL@features, pre_trained = local_glove_ALL, verbose = FALSE)
