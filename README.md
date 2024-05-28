## Comparative Analysis of Countries' Perspectives on 'Rule of Law' in the U.N. Security Council Debates Leveraging the conText Embedding Regression

### Group

![]()Jingyi Chen (A17519136)

### Introduction

...

### Data

#### Overview

The main data analyzed in this project is the United Nations Security Council debates from Harvard Dataverse (Schoenfeld et al., 2019). The filtered data include 8435 speeches that mentioned "rule of law" from April 1995 to November 2020 and their document IDs, as well as the covariates like country, speaker, date, and topic.

#### Data Preprocessing

The original dataset from Schoenfeld et al. (2019) consists of two files: "docs_meta.RData" and "docs.RData", which were merged using the shared document IDs. Because the primary objective of this project is to examine how the phrase "rule of law" is used by different countries in their U.N. Security Council speeches, it was made into one term, i.e. "ruleoflaw", which is the targeted/focal term in the analysis. Also, because I am also interested in whether some countries are more likely to associated "human rights" with "ruleoflaw", the former phrase is also made into one term, i.e. "humanrights". The whole dataset of speeches were filtered into only those that mentioned "ruleoflaw". In the meantime, I also compute the proportion of speeches that mentioned "ruleoflaw" among all speeches in a given year year and the below histogram illustrates the results:

![The Proportion of U N  Security Council Speeches Mentioning 'rule of law' by Year](https://github.com/jchensd/POLI_179_Jingyi_Chen/assets/169096479/2df11eda-0646-46ce-9675-d4808275768f)

Then, I converted the column of texts into a corpus and tokens. I also conducted common text pre-processing using the "quanteda" package, including removing punctuation, symbols, numbers, separators, English stopwords, words with 2 or fewer characters and words appearing less than 5 times in the corpus (I used "padding=TRUE" to leave an empty string where the removed tokens previously existed), and converting words to lower case.

In order to analyze the words surronding the targeted term "ruleoflaw",

### Methods

#### 1. conText Regression

7103 speeches

### Results

### Discussions

### References

Pennington, J., Socher, R., & Manning, C. D. (2014). Glove: Global vectors for word representation. In Proceedings of the 2014 conference on empirical methods in natural language processing (EMNLP) (pp. 1532-1543).

Rodriguez, P. L., Spirling, A., & Stewart, B. M. (2023). Embedding Regression: Models for Context-Specific Description and Inference. American Political Science Review, 117(4), 1255–1274. <doi:10.1017/S0003055422001228>

Schoenfeld, M., Eckhard, S., Patz, R., Meegdenburg, H. van, & Pires, A. (2019). The UN Security Council Debates (Version V5) [Data set]. Harvard Dataverse. <https://doi.org/10.7910/DVN/KGVSYH>
