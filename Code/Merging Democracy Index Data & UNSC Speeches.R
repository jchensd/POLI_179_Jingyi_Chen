#set my working directory
setwd("/Users/jingyichen/Library/Mobile Documents/com~apple~CloudDocs/POLI 179/POLI_179_Jingyi_Chen/Data & Models")
#load libraries
library(tidyverse)
#clear all previous objects.
#rm(list = ls())
#load the democracy index 2010 data.
democracy_index_2010 <- read.csv("democracy-index-eiu.csv") %>%
  filter(Year == 2010)
#rename the country/region variable
democracy_index_2010 <- democracy_index_2010 %>% rename(country = Entity)

# Function to trim and normalize spaces
clean_string <- function(x) {
  x <- trimws(x)               # Trim leading and trailing whitespace
  x <- gsub("\\s+", " ", x)    # Replace multiple spaces with a single space
  return(x)
}
# Apply the cleaning function to the 'country' column
democracy_index_2010$country <- sapply(democracy_index_2010$country, clean_string)
#load the U.N. Security Council speeches data.
filtered_ALLspeeches <- readRDS("filtered_ALLspeeches.rds")
# Apply the cleaning function to the 'country' column
filtered_ALLspeeches$country <- sapply(filtered_ALLspeeches$country, clean_string)
#Directly change inconsistent names in the 'country' column using recode
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
filtered_ALLspeeches <- filtered_ALLspeeches %>%
  mutate(country = recode(country,
                          "Minister For Foreign Affairs Of Ghana" = "Ghana",
                          "Former Yugoslav Republic Of Macedonia" = "Republic of North Macedonia"
                          
  ))
#merge the democracy index dataset and the U.N. Security Council speeches dataset.
merged_countries_democracy_index <- merge(democracy_index_2010, filtered_ALLspeeches, by = "country")

#save the merged dataset.
saveRDS(merged_countries_democracy_index, file = "merged_countries_democracy_index.rds")
#find unmatched observations
unmatched_democracy_index <- anti_join(democracy_index_2010, filtered_ALLspeeches, by = "country")
unmatched_speeches <- anti_join(filtered_ALLspeeches, democracy_index_2010, by = "country")
unique(unmatched_speeches$country)

