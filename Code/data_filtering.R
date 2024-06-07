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