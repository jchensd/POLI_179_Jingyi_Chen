#set my working directory
setwd("/Users/jingyichen/Library/Mobile Documents/com~apple~CloudDocs/POLI 179/POLI 179_All Data")

#clear all previous objects.
rm(list = ls())

#---------------------------------
# Merging and filtering dataset
#---------------------------------
#read in my datasets.
load("docs_meta.RData")
load("docs.RData")
#load packages
library(dplyr)
library(stringr)
#re-label the column "filename" as "doc_id".
meta_speeches <- meta_speeches %>%
  rename("doc_id" = "filename")

#merge the text dataset and the metadata dataset.
merged_ALLspeeches <- merge(raw_docs, meta_speeches, by = "doc_id")
#make "rule of law" into one word
merged_ALLspeeches$text <- gsub("\n", " ", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("  ", " ", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("rule of law", "ruleoflaw", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("rule-of-law", "ruleoflaw", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("rule oflaw", "ruleoflaw", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("ruleof law", "ruleoflaw", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("human rights", "humanrights", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("Security Council", "SecurityCouncil", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("United Nations", "UnitedNations", merged_ALLspeeches$text, ignore.case = TRUE)
#create a new variable "contain_ruleoflaw" that takes the value of 1 when the speech mention ruleoflaw and 0 when it doesn't.
merged_ALLspeeches <- merged_ALLspeeches %>%
  mutate(contain_ruleoflaw = ifelse(grepl("ruleoflaw", text), 1, 0))
#compute the proportion of speeches that mention "rule of law" each year.
RofL_proportion_by_year <- merged_ALLspeeches %>% 
  group_by(year) %>% 
  summarize(mention_RofL_proportion = mean(contain_ruleoflaw))
#draw a bar graph for proportions of speeches mentioning "rule of law" each year.
library(ggplot2)
# Create a bar graph
ggplot(RofL_proportion_by_year, aes(x = factor(year), y = mention_RofL_proportion)) +
  geom_bar(stat = "identity", fill = "darkgreen") +
  labs(x = "Year", y = "Proportion of Speeches Mentioning 'rule of law'", title = "The Proportion of U.N. Security Council Speeches Mentioning 'rule of law' by Year") +
  theme_minimal()  +
  theme(plot.background = element_rect(fill = "lightgray", color = NA), # Changes the entire plot area background
        panel.background = element_rect(fill = "white", color = NA))    # Changes the panel (where the bars are) background
#filter the dataset to include only those texts that contain "ruleoflaw"
filtered_ALLspeeches <- merged_ALLspeeches %>%
  filter(str_detect(text, regex("ruleoflaw", ignore_case = TRUE)))
saveRDS(filtered_ALLspeeches, file = "filtered_ALLspeeches.rds")

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

#---------------------------------
# Estimate glove model
#---------------------------------
#load package
library(text2vec)
library(parallel)
library(data.table)
#construct the feature co-occurrence matrix for the toks_ALLspeeches object
toks_fcm_ALLspeeches <- fcm(toks_ALLspeeches, context = "window", window = 6, count = "frequency", tri = FALSE) 

#estimate glove model 
glove_ALLSpeeches <- GlobalVectors$new(rank = 300, 
                                       x_max = 50,
                                       learning_rate = 0.05)
wv_main_ALL <- glove_ALLSpeeches$fit_transform(toks_fcm_ALLspeeches, n_iter = 50,
                                               convergence_tol = 1e-4, 
                                               n_threads = parallel::detectCores(), shuffle_seed = 2024L) 

wv_context_ALL <- glove_ALLSpeeches$components
local_glove_ALL <- wv_main_ALL + t(wv_context_ALL) # word vectors
#Save the trained glove embeddings to RDS
saveRDS(local_glove_ALL, "local_glove_ALL.rds")

# qualitative check
find_nns(local_glove_ALL['ruleoflaw', ], pre_trained = local_glove_ALL, N = 5, candidates = features_ALLspeeches)

# compute transform (A matrix)
local_transform_ALL <- compute_transform(x = toks_fcm_ALLspeeches, pre_trained = local_glove_ALL, weighting = "log")
saveRDS(local_transform_ALL, "local_transform_ALL.rds")
#-----------------------------------------------
#load the saved models
#local_glove_ALL <- readRDS("local_glove_ALL.rds")
#local_transform_ALL <- readRDS("local_transform_ALL.rds")


#create document-embedding matrix using our locally trained GloVe embeddings and transformation matrix
RofL_dem_local_glove_ALL <- dem(x = ruleoflaw_dfm, pre_trained = local_glove_ALL, transform = TRUE, transform_matrix = local_transform_ALL, verbose = TRUE)


# take the column average to get a single "corpus-wide" embedding
RofL_wv_local_glove_ALL <- colMeans(RofL_dem_local_glove_ALL)

# find nearest neighbors for overall ruleoflaw embedding
nn_features_overall <- as.data.frame(nns(RofL_wv_local_glove_ALL, pre_trained = local_glove_ALL, N = 15, candidates = RofL_dem_local_glove_ALL@features, as_list = FALSE))

#to get group-specific embeddings, average within country
ruleoflaw_wv_country_local_ALL <- dem_group(RofL_dem_local_glove_ALL, groups = RofL_dem_local_glove_ALL@docvars$country)
dim(ruleoflaw_wv_country_local_ALL)

#find nearest neighbors by country
#if setting as_list = FALSE combines each group's results into a single tibble (useful for joint plotting)
ruleoflaw_nns_local_ALL <- nns(ruleoflaw_wv_country_local_ALL, pre_trained = local_glove_ALL, N = 15, candidates = ruleoflaw_wv_country_local_ALL@features, as_list = TRUE)

#check out results for countries
nn_features_China <- as.data.frame(ruleoflaw_nns_local_ALL[["China"]])
nn_features_US <- as.data.frame(ruleoflaw_nns_local_ALL[["United States Of America"]])

#compute the cosine similarity between each country's embedding and a specific set of features
cos_similarity_stability <- cos_sim(ruleoflaw_wv_country_local_ALL, pre_trained = local_glove_ALL, features = c('stability'), as_list = FALSE) %>% 
  arrange(desc(value))
cos_similarity_humanrights <- cos_sim(ruleoflaw_wv_country_local_ALL, pre_trained = local_glove_ALL, features = c('humanrights'), as_list = FALSE) %>% 
  arrange(desc(value))

#compute the cosine similarity between each country's embedding and a specific set of features
nns_ratio_China_US <- as.data.frame(nns_ratio(x = ruleoflaw_wv_country_local_ALL[c("China", "United States Of America"), ], N = 10, numerator = "China", candidates = ruleoflaw_wv_country_local_ALL@features, pre_trained = local_glove_ALL, verbose = FALSE))
nns_ratio(x = ruleoflaw_wv_country_local_ALL[c("China", "United States Of America"), ], N = 20, numerator = "United States Of America", candidates = ruleoflaw_wv_country_local_ALL@features, pre_trained = local_glove_ALL, verbose = FALSE)

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
merged_countries <- readRDS("merged_countries.rds")

#Text pre-processing------------------------------------------------------------
#-------------------------------------------------------------------------------
#create a corpus of texts.
corpus_merged_countries <- corpus(merged_countries, text_field = "text")

#tokenize corpus removing unnecessary (i.e. semantically uninformative) elements
toks_merged_countries <- tokens(corpus_merged_countries, remove_punct=T, remove_symbols=T, remove_numbers=T, remove_separators=T)
toks_merged_countries <- tokens_tolower(toks_merged_countries)
#clean out stopwords and words with 2 or fewer characters
toks_merged_countries <- tokens_select(toks_merged_countries, pattern = stopwords("en"), selection = "remove", min_nchar=3)
#only use features that appear at least 5 times in the corpus
features_merged_countries <- dfm(toks_merged_countries, verbose = FALSE) %>% 
  dfm_trim(min_termfreq = 5) %>% featnames()


# leave the pads so that non-adjacent words will not become adjacent
toks_merged_countries_features <- tokens_select(toks_merged_countries, features_merged_countries, padding = TRUE)
#regress 
all_countries_model <- conText(formula = "ruleoflaw" ~ country,
                               data = toks_merged_countries_features,
                               pre_trained = local_glove_ALL,
                               transform = TRUE, transform_matrix = local_transform_ALL,
                               jackknife = TRUE, confidence_level = 0.95,
                               permute = TRUE, num_permutations = 100,
                               window = 6, case_insensitive = TRUE,
                               verbose = FALSE)

#non-binary covariates are automatically "dummified"
rownames(all_countries_model)
regression_info_all_countries <- data.frame(country = all_countries_model@normed_coefficients[["coefficient"]], normed_estimate = all_countries_model@normed_coefficients[["normed.estimate"]], std_error = all_countries_model@normed_coefficients[["std.error"]], lower_ci = all_countries_model@normed_coefficients[["lower.ci"]], upper_ci = all_countries_model@normed_coefficients[["upper.ci"]], p_value = all_countries_model@normed_coefficients[["p.value"]])
regression_info_China <- as.data.frame(regression_info_all_countries[regression_info_all_countries$country == "country_China", ])
regression_info_US <- as.data.frame(regression_info_all_countries[regression_info_all_countries$country == "country_United States Of America", ])
# D-dimensional beta coefficients
# the intercept in this case is the ALC embedding for?
# beta coefficients can be combined to get each group's ALC embedding
intercept_wv <- all_countries_model['(Intercept)',] 
nns_regression_intercept <- as.data.frame(nns(rbind(intercept_wv), N = 15, pre_trained = local_glove_ALL, candidates = all_countries_model@features))
China_wv <- all_countries_model['(Intercept)',] + all_countries_model['country_China',] #China
# nearest neighbors
nns_regression_China <- as.data.frame(nns(rbind(China_wv), N = 15, pre_trained = local_glove_ALL, candidates = all_countries_model@features))
# Compute embeddings for countries 
US_wv <- all_countries_model['(Intercept)',] + all_countries_model['country_United States Of America',]
nns_regression_US <- as.data.frame(nns(rbind(US_wv), N = 15, pre_trained = local_glove_ALL, candidates = all_countries_model@features))


merged_countries_democracy_index <- readRDS("merged_countries_democracy_index.rds")
#create a new variable "contain_ruleoflaw" that takes the value of 1 when the speech mention ruleoflaw and 0 when it doesn't.
merged_countries_democracy_index <- merged_countries_democracy_index %>%
  mutate(China = ifelse(grepl("China", country), 1, 0))
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
nearest_neighbors_dem_index <- nns(rbind(percentile_wvs_dem_index), N = 20, pre_trained = local_glove_ALL, candidates = democracy_index_model@features)

#non-binary covariates are automatically "dummified"
rownames(democracy_index_model)
regression_info_democracy_index_model <- data.frame(country = democracy_index_model@normed_coefficients[["coefficient"]], normed_estimate = democracy_index_model@normed_coefficients[["normed.estimate"]], std_error = democracy_index_model@normed_coefficients[["std.error"]], lower_ci = democracy_index_model@normed_coefficients[["lower.ci"]], upper_ci = democracy_index_model@normed_coefficients[["upper.ci"]], p_value = democracy_index_model@normed_coefficients[["p.value"]])
regression_info_China <- as.data.frame(regression_info_democracy_index_model[regression_info_democracy_index_model$country == "country_China", ])
regression_info_US <- as.data.frame(regression_info_all_countries[regression_info_all_countries$country == "country_United States Of America", ])
# D-dimensional beta coefficients
# the intercept in this case is the ALC embedding for?
# beta coefficients can be combined to get each group's ALC embedding
intercept_wv <- democracy_index_model['(Intercept)',] 
nns_regression_intercept <- as.data.frame(nns(rbind(intercept_wv), N = 15, pre_trained = local_glove_ALL, candidates = democracy_index_model@features))
China_wv <- democracy_index_model['(Intercept)',] + democracy_index_model['China',] #China
# nearest neighbors
nns_regression_China <- as.data.frame(nns(rbind(China_wv), N = 15, pre_trained = local_glove_ALL, candidates = all_countries_model@features))
# Compute embeddings for countries 
US_wv <- all_countries_model['(Intercept)',] + all_countries_model['country_United States Of America',]
nns_regression_US <- as.data.frame(nns(rbind(US_wv), N = 15, pre_trained = local_glove_ALL, candidates = all_countries_model@features))


#I am still exploring the following...
#STM 
library(stm)
#convert the trimmed dfm into the format that can be used to run the STM model.
dfm_merged_countries_dem_index <- convert(dfm_merged_countries_dem_index, to = "stm")
#run the STM model.
model.stm_RofL <- stm(dfm_merged_countries_dem_index$documents, dfm_merged_countries_dem_index$vocab, K = 10, prevalence = ~ s(year) + country + s(Democracy.score),
                    data = dfm_merged_countries_dem_index$meta)
#Find most likely words in each topic
labelTopics(model.stm_RofL)
#Estimate relationship between democracy score and topics
model.stm.ee_RofL <- estimateEffect(1:10 ~ s(year) + country, model.stm_RofL, meta = dfm_merged_countries_dem_index$meta)

plot(model.stm.ee_RofL, "country", method="difference", cov.value1="United States Of America", cov.value2="Russian Federation")
plot(model.stm.ee_RofL, "Democracy.score", method="continuous", topics=c(10))

#---------cos similarity-----------
# Compute cosine similarity between China and the United States embeddings
cosine_similarity <- function(vec1, vec2) {
  sum(vec1 * vec2) / (sqrt(sum(vec1^2)) * sqrt(sum(vec2^2)))
}

china_us_similarity <- cosine_similarity(China_wv, US_wv)

# Identify features with most significant differences
# Calculate the differences in embeddings
embedding_diff <- China_wv - US_wv
nns(rbind(embedding_diff), N = 15, pre_trained = local_glove_ALL, candidates = all_countries_model@features)
# Find the top N features with the largest differences
top_diff_features <- names(sort(nns(embedding_diff), decreasing = TRUE)[1:10])
#create a sparse matrix for estimated embeddings for China and the U.S. and compute the ratio of cosine similarities
library(Matrix)
matrix_China_US_wv <- sparseMatrix(i = rep(1:2, each=300), 
             j = rep(1:300, times=2), 
             x = c(China_wv, US_wv))
nns_ratio_regression_China_US <- as.data.frame(nns_ratio(x = matrix_China_US_wv, N = 10, candidates = ruleoflaw_wv_country_local_ALL@features, pre_trained = local_glove_ALL, verbose = FALSE))

# Display top differences
print(top_diff_features)

#regress the embeddings over GDP per capita
GDPpercap_model <- conText(formula = "ruleoflaw" ~ GDP_PerCap,
                              data = toks_merged_countries_features,
                              pre_trained = local_glove_ALL,
                              transform = TRUE, transform_matrix = local_transform_ALL,
                              jackknife = TRUE, confidence_level = 0.95,
                              permute = TRUE, num_permutations = 100,
                              window = 6, case_insensitive = TRUE,
                              verbose = FALSE)
# look at percentiles of GDPpercap
percentiles_GDPpercap <- quantile(docvars(corpus_merged_countries)$GDP_PerCap, probs = seq(0.05,0.95,0.05))
percentile_wvs_GDPpercap <- lapply(percentiles_GDPpercap, function(i) GDPpercap_model["(Intercept)",] + i*GDPpercap_model["GDP_PerCap",]) %>% do.call(rbind,.)
percentile_sim_GDPpercap <- cos_sim(x = percentile_wvs_GDPpercap, pre_trained = local_glove_ALL, features = c("support", "illegal", "stability", "humanrights", "justice", "security", "accountability"), as_list = TRUE)
# nearest neighbors
nearest_neighbors_gdpPerCap <- nns(rbind(percentile_wvs_GDPpercap), N = 15, pre_trained = local_glove_ALL, candidates = GDPpercap_model@features)

