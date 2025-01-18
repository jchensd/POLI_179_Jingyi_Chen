
#This code merges and cleans the original raw datasets of United Nations Security Council speeches.

#For this study, the dataset is filtered to the speeches that mentioned the rule of law.

#It also visualizes trends in speech volume from 1995 to 2020.

#set my working directory
setwd("~/Library/Mobile Documents/com~apple~CloudDocs/Past Courses/POLI 179/POLI_179_Jingyi_Chen/Data & Models")

#clear all previous objects.
rm(list = ls())

#---------------------------------
# Merging, cleaning, and filtering the United Nations Security Council debate dataset
#---------------------------------
#read in the datasets. 
#The source is The UN Security Council Debates dataset, available at <https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/KGVSYH>. 
#The data is licensed under the CC0 1.0 Universal <https://creativecommons.org/publicdomain/zero/1.0/>.
#Attribution: Schoenfeld et al., 2019 (See References)
load("docs_meta.RData")
load("docs.RData")

#load packages
library(dplyr)
library(stringr)
library(ggplot2)

#re-label the column "filename" as "doc_id".
meta_speeches <- meta_speeches %>%
  rename("doc_id" = "filename")
#merge the text dataset and the metadata dataset.
merged_ALLspeeches <- merge(raw_docs, meta_speeches, by = "doc_id")

#replace newline characters and extra spaces with one space
merged_ALLspeeches$text <- gsub("\n", " ", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("  ", " ", merged_ALLspeeches$text, ignore.case = TRUE)

#standardize "rule of law" to one term "ruleoflaw". 
#removes inconsistencies caused by spaces, hyphens, or different capitalizations.
merged_ALLspeeches$text <- gsub("rule of law", "ruleoflaw", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("rule-of-law", "ruleoflaw", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("rule oflaw", "ruleoflaw", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("ruleof law", "ruleoflaw", merged_ALLspeeches$text, ignore.case = TRUE)

#standardize human rights, Security Council, and United Nations into single terms
#in order to avoid misrepresentations of their contextual meanings in the future text analysis
merged_ALLspeeches$text <- gsub("human rights", "humanrights", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("Security Council", "SecurityCouncil", merged_ALLspeeches$text, ignore.case = TRUE)
merged_ALLspeeches$text <- gsub("United Nations", "UnitedNations", merged_ALLspeeches$text, ignore.case = TRUE)

#create a new variable "contain_ruleoflaw" that takes the value of 1 when the speech mention ruleoflaw and 0 when it doesn't.
merged_ALLspeeches <- merged_ALLspeeches %>%
  mutate(contain_ruleoflaw = ifelse(grepl("ruleoflaw", text), 1, 0))

#filter the dataset to include only those texts that contain "ruleoflaw"
filtered_ALLspeeches <- merged_ALLspeeches %>%
  filter(contain_ruleoflaw == 1)

#filter the dataset to include only those texts by China and the US that contain "ruleoflaw"
US_China_UNSC_speeches <- filtered_ALLspeeches %>% 
  filter(country == "China" | country == "United States Of America")

#save the filtered data as RDS files
saveRDS(US_China_UNSC_speeches, file = "US_China_UNSC_speeches.rds")
saveRDS(filtered_ALLspeeches, file = "filtered_ALLspeeches.rds")


#---------------------------------
# Descriptive visualization of the dataset
#---------------------------------
#compute the proportion of speeches that mention "rule of law" each year.
RofL_proportion_by_year <- merged_ALLspeeches %>% 
  group_by(year) %>% 
  summarize(mention_RofL_proportion = mean(contain_ruleoflaw))

#draw a bar graph for proportions of speeches mentioning "rule of law" each year.
ggplot(RofL_proportion_by_year, aes(x = factor(year), y = mention_RofL_proportion)) +
  geom_bar(stat = "identity", fill = "darkgreen") +
  labs(x = "Year", y = "Proportion of Speeches Mentioning 'rule of law'", title = "The Proportion of U.N. Security Council Speeches Mentioning 'rule of law' by Year") +
  theme_minimal()  +
  theme(plot.background = element_rect(fill = "lightgray", color = NA), # Changes the entire plot area background
        panel.background = element_rect(fill = "white", color = NA))    # Changes the panel (where the bars are) background
