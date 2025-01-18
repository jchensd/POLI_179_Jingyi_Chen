
#This code cleans and merges the Democracy Index dataset and the previously filtered UNSC speech dataset.

#set my working directory
setwd("~/Library/Mobile Documents/com~apple~CloudDocs/Past Courses/POLI 179/POLI_179_Jingyi_Chen/Data & Models")

#load libraries
library(tidyverse)

#clear all previous objects.
#rm(list = ls())

#---------------------------------
# Cleaning the Democracy Index dataset. Standardize the country variable in both datasets for successful merging. 
#---------------------------------
#load the democracy index 2010 data.
#The source is the Democracy Index dataset, available at <https://ourworldindata.org/grapher/democracy-index-eiu>. 
#The dataset is governed by the EIU’s licensing terms and conditions, as outlined in their Terms and conditions of access <https://www.eiu.com/n/terms/>.
#Attribution: Economist Intelligence Unit (2010) (See References)
democracy_index_2010 <- read.csv("democracy-index-eiu.csv") %>%
  filter(Year == 2010)

#load the U.N. Security Council speeches data, which have been filtered in Data Pre-Processing.R.
ALLspeeches <- readRDS("filtered_ALLspeeches.rds")

#rename the country/region variable for consistency with the UNSC dataset.
democracy_index_2010 <- democracy_index_2010 %>% rename(country = Entity)

#trim and normalize spaces for the "country" variable for the democracy index and the UNSC datasets.
democracy_index_2010$country <- gsub("\\s+", " ", trimws(democracy_index_2010$country))
ALLspeeches$country <- gsub("\\s+", " ", trimws(ALLspeeches$country))

#in order to merge the two datasets, in which some country names are formatted differently,
#this code manually renames inconsistent names in the 'country' column using recode
democracy_index_2010 <- democracy_index_2010 %>%
  mutate(country = recode(country,
                          "United States" = "United States Of America",
                          "Bosnia and Herzegovina" = "Bosnia And Herzegovina",
                          "United Kingdom" = "United Kingdom Of Great Britain And Northern Ireland",
                          "Democratic Republic of Congo" = "Democratic Republic Of The Congo",
                          "Cote d'Ivoire" = "Cote D'Ivoire",
                          "Russia" = "Russian Federation",
                          "South Korea" = "Republic Of Korea",
                          "Iran" = "Islamic Republic Of Iran",
                          "Tanzania" = "United Republic Of Tanzania",
                          "Slovakia" = "Slovak Republic",
                          "Syria" = "Syrian Arab Republic",
                          "East Timor" = "Timor-Leste",
                          "North Macedonia" = "Republic of North Macedonia",
                          "Bolivia" = "Bolivia (Plurinational State Of)",
                          "Czechia" = "Czech Republic",
                          "Moldova" = "Republic Of Moldova",
                          "Venezuela" = "Venezuela (Bolivarian Republic Of)",
                          "Trinidad and Tobago" = "Trinidad And Tobago",
                          "Vietnam" = "Viet Nam"
  ))

#---------------------------------
# Merge the datasets and check unmatched observations
#---------------------------------
#merge the Democracy Index dataset and the UNSC speech dataset by country.
merged_countries_democracy_index <- merge(democracy_index_2010, ALLspeeches, by = "country")

#check the countries included in the merged dataset.
unique(merged_countries_democracy_index$country)

#check unmatched observations to ensure all the countries that have data in both datasets are correctly merged.
#identify countries in the Democracy Index dataset that do not match any countries in the UNSC dataset.
unmatched_democracy_index <- anti_join(democracy_index_2010, ALLspeeches, by = "country")
#identify countries in the UNSC dataset that do not match any countries in the Democracy Index dataset.
unmatched_speeches <- anti_join(ALLspeeches, democracy_index_2010, by = "country")
unique(unmatched_speeches$country)

#save the merged dataset.
saveRDS(merged_countries_democracy_index, file = "merged_countries_democracy_index.rds")
