## Decoding Country Perspectives on "Rule of Law" in U.N. Security Council Debates: A Comparative Analysis Leveraging conText Embedding Regression

### Group

![]()Jingyi Chen (A17519136)

### Overview

Rule of law is a fundamental concept in international conflicts, collaborations, and state governance. The mentioning of rule of law in the U.N. Security Council had increase in the last two decades. While it was not frequently brought up during the debates, with about 10 percents of speeches that mentioned it among all speeches per year in the past 20 years (Figure 1), the manner in which countries discuss this concept can provide implications about their values and goals on the international stage. In this project, by applying the à la carte (ALC) Embedding (Khodak et al., 2018) and the conText Embedding Regression (Rodriguez et al., 2023) to compare the contextual meanings of "rule of law" in the United Nations Security Council debates between the U.S. and China and across countries with different democracy scores (Economist Intelligence Unit, 2010), I tried to understand whether there were distinctions in how countries viewed this concept. The code for main analyses is in [Final Project_POLI 179.R](https://github.com/jchensd/POLI_179_Jingyi_Chen/blob/d0fc39ebfb176129d403e680eb5abf07f65502fd/Code/Final%20Project_POLI%20179.R)
See References for the links to the data used in this project.

### Data

#### Overview

The main data analyzed in this project is the United Nations Security Council debates (Schoenfeld et al., 2019). The filtered data include 9441 speeches that mentioned "rule of law" from January 1995 to December 2020 and their document IDs, as well as the metadata including country, speaker, and date.

#### Data Preprocessing

I conducted the following preprocessings in [data_filtering.R](https://github.com/jchensd/POLI_179_Jingyi_Chen/blob/ef70e7bbbf63fb10eb63cd0dd412302890c8fce7/Code/data_filtering.R).

I merged the separate files of the original data package using the shared document IDs. Because the primary objective of this project is to examine how the phrase "rule of law", or the targeted/focal term, is used by different countries, it was made into one term, i.e. "ruleoflaw". Also, because I am also interested in whether some countries are more likely to link "human rights" to "ruleoflaw", the former phrase is also made into one term, i.e. "humanrights". "United Nations" and "Security Council" were also made into single terms. The whole dataset of speeches were filtered into only those that mentioned "ruleoflaw".

Then, I converted the column of texts into a corpus and tokens. I also conducted common text pre-processing using the "quanteda" package, including removing punctuation, symbols, numbers, separators, English stopwords, words with 2 or fewer characters and words appearing less than 5 times in the corpus (I used "padding=TRUE" to leave an empty string where the removed tokens previously existed), and converting words to lower case.

![Figure 1: Proportions of U.N. Security Council Speeches Mentioning 'Rule of Law' by Year](https://github.com/jchensd/POLI_179_Jingyi_Chen/assets/169096479/2e72ba6c-7540-4a3a-b6a6-af5afb57365f)

### Methods

#### 1. à la carte (ALC) Embedding

I used the "conText" package developed by (Rodriguez et al., 2023) to conduct analysis in R. In order to examine the contextual meanings of "ruleoflaw" by analyzing words surrounding this term, I collected 6 words before and after every instance in which "ruleoflaw" was mentioned among the speeches as well as the metadata associated with the instance. A document feature matrix was built, where the rows were the total 16145 instances of "ruleoflaw".

Then, I estimated GloVe embeddings from the 9441 U.N. Security Council speeches using the "text2vec" package. A transform matrix (Matrix A) was computed using the "compute-transform" function. It helps weight the common, uninformative words lower in the embeddings. The code for estimating the GloVe model is in...

The ALC embedding method estimates the embedding of the targeted word in a specific context by taking the average of the embeddings of words surrounding this word (e.g. 6 words before and after the targeted word) (Khodak et al., 2018). I obtained the embeddings of the words surrounding the 16145 instances of "ruleoflaw" from the GloVe model estimated previously and applied the transform matrix to construct a document-embedding matrix which contains the embeddings. Then, I took the column average of these embeddings to get the context-specific embedding for "ruleoflaw". With the GloVe embedding model, I found nearest neighbor features for country-specific "ruleoflaw" embeddings. I also computed cosine similarities between China and U.S.'s "ruleoflaw" embeddings and available features in the corpus to find words that distinguish two countries the most. To obtain the ratios, it first computed the cosine similarities between the embeddings of "ruleoflaw" and available features in the corpus for China and the U.S. Then, it takes the ratio of cosine similarities between the two countries for each features.

#### 2. conText Embedding Regression

Using the conText regression model, I regressed the embedding of "ruleoflaw" over the 2010 Democracy Index. Before doing so, I merged the U.N. Security Council dataset with the 2010 Democracy Index data. Speeches by NGOs, supranational unions, and a few countries for which Democracy Index data were unavailable were removed from the dataset. There are 7879 speeches by countries left. The code for data preprocessing and merging is in...

After constructing the regression, I obtained the embeddings for countries at every 5th percentile of democracy index that were estimated by the regression and found nearest neighbor features. I mainly compared countries at 5th and 95th percentiles of democracy index by computing ratios of cosine similarities.

### Results

#### Nearest Neighbors Based on ALC Embedding

Table 1 shows the nearest neighbors for the overall "ruleoflaw" embedding from the whole corpus (i.e. 9441 U.N. Security Council speeches that mentioned "ruleoflaw"). Overall, delegates of countries or organizations emphasized the importance of rule of law and linked it to democratic concepts and human rights.

Tables 2 & 3 presents the nearest neighbor features for the specific contexts of China and the U.S., respectively. Table 4 displays the ratios of cosine similarities. The features with values larger than 1 are more associated with "ruleoflaw" in China's context compared to the U.S.'s context; vise versa, features with values smaller than 1 are more associated with "ruleoflaw" in the U.S.'s context compared to China's context. The interpretation is that the U.S. tends to understand rule of law as protection of individuals' rights during international crises and the institutions and governance in the international decision-making process. In contrast, China tends to link it to stability, security, and economic development.

**Table 1**:

| **feature**   | **rank** | **value** |
|:--------------|:---------|:----------|
| ruleoflaw     | 1        | 0.9131961 |
| strengthening | 2        | 0.7963212 |
| respect       | 3        | 0.7717734 |
| institutions  | 4        | 0.7662984 |
| governance    | 5        | 0.7577117 |
| humanrights   | 6        | 0.7551350 |
| essential     | 7        | 0.7542815 |
| justice       | 8        | 0.7154632 |
| ensuring      | 9        | 0.7127769 |
| promoting     | 10       | 0.7118825 |

**Table 2**:

| **feature**   | **rank** | **value** |
|:--------------|:---------|:----------|
| ruleoflaw     | 1        | 0.7990605 |
| stability     | 2        | 0.7661675 |
| development   | 3        | 0.7271184 |
| strengthening | 4        | 0.7197165 |
| institutions  | 5        | 0.7150364 |
| essential     | 6        | 0.7013694 |
| promote       | 7        | 0.6952098 |
| security      | 8        | 0.6859930 |
| efforts       | 9        | 0.6810040 |
| strengthen    | 10       | 0.6791745 |

**Table 3**:

| **feature**   | **rank** | **value** |
|:--------------|:---------|:----------|
| ruleoflaw     | 1        | 0.8580669 |
| institutions  | 2        | 0.7776769 |
| governance    | 3        | 0.7363304 |
| strengthen    | 4        | 0.7262979 |
| strengthening | 5        | 0.7179879 |
| respect       | 6        | 0.7093298 |
| promote       | 7        | 0.6938324 |
| essential     | 8        | 0.6928845 |
| humanrights   | 9        | 0.6892298 |
| build         | 10       | 0.6694275 |

**Table 4**:

| rank   | **feature**   | **value** |
|:-------|:--------------|:----------|
| **1**  | economic      | 1.2485221 |
| **2**  | development   | 1.2004488 |
| **3**  | stability     | 1.1930074 |
| **4**  | security      | 1.1005233 |
| **5**  | efforts       | 1.0579386 |
| **6**  | essential     | 1.0122458 |
| **7**  | strengthening | 1.0024076 |
| **8**  | promote       | 1.0019851 |
| **9**  | respect       | 0.9504743 |
| **10** | strengthen    | 0.9351184 |
| **11** | ruleoflaw     | 0.9312333 |
| **12** | democracy     | 0.9219601 |
| **13** | institutions  | 0.9194518 |
| **14** | build         | 0.8939435 |
| **15** | governance    | 0.8632018 |
| **16** | humanrights   | 0.8387187 |

#### conText Embedding Regression Results

The regression model outputs a p-value of 0 and lower and higher confidence intervals of 0.06375997 and 0.07463132, indicating the repression result is significant. Based on the nearest neighbor features (not presented here due to page limitation) for embedding of "ruleoflaw" for countries at every 5th percentile, as estimated by the regression, even countries at 95th percentile and 5th percentile have similar top nearest neighbors like "strengthening" and "respect", indicating their shared acknowledgement of the importance of rule of law. However, when taking the ratios of cosine similarities, the results show that countries at 5th percentile tend to link the phrase to "stability" (ratio: 0.9238250) and "democracy" (0.9656132, not as significant as "stability"), while those at 95th percentile tend to emphasize its importance and associate it with human rights (1.0519852) and justice (1.0468595). Table 5 displays the ratios of cosine similarities between countries at 95th percentile and 5th percentile of democracy index.

Considering that China typically connects rule of law to stability, I removed all speeches by China from the dataset and ran the regression again. Still, "stability" has the lowest cosine similarity ratio (0.9450454), suggesting that linking rule of law to stability is a common observation for countries with low democracy scores, not uniquely for China, though it is a very typical example.

**Table 5**:

| rank   | **feature**   | **value** |
|:-------|:--------------|:----------|
| **1**  | crucial       | 1.0769875 |
| **2**  | regard        | 1.0715406 |
| **3**  | essential     | 1.0524188 |
| **4**  | humanrights   | 1.0519852 |
| **5**  | justice       | 1.0468595 |
| **6**  | ensuring      | 1.0364412 |
| **7**  | ruleoflaw     | 1.0223068 |
| **8**  | fundamental   | 1.0195719 |
| **9**  | strengthen    | 1.0158669 |
| **10** | strengthening | 1.0152380 |
| **11** | institutions  | 1.0081698 |
| **12** | respect       | 1.0041441 |
| **13** | promotion     | 0.9917010 |
| **14** | governance    | 0.9786736 |
| **15** | promoting     | 0.9721091 |
| **16** | democracy     | 0.9656132 |
| **17** | promote       | 0.9601427 |
| **18** | stability     | 0.9238250 |

### Discussions

Based on the results from ALC embedding and conText Regression, this study found that, in the scenario of U.N. Security Council debates, countries like China and the U.S. showed different understandings of rule of law. The U.S. presents a traditional Western liberal-democratic interpretation of rule of law, while China possibly considers it as a pragmatic means to broader socioeconomic and political goals. Also, states with lower democracy scores tend to link rule of law to stability, which might suggest maintaining stability holds high importance for non-democratic countries.

One limitation of this study is the lack of understanding of why the countries associate rule of law with distinct words in the broader context of international politics. In the future, it would be helpful to integrate background insights about state policies and international relations to better understand what the findings suggest about countries' different perspectives regarding rule of law, and how this could help explain international conflicts and collaborations.

### References

Economist Intelligence Unit. (2010). Democracy Index [Data set]. Our World in Date. <https://ourworldindata.org/grapher/democracy-index-eiu>

Khodak, M., Saunshi, N., Liang, Y., Ma, T., Stewart, B., & Arora, S. (2018). A la carte embedding: Cheap but effective induction of semantic feature vectors. *arXiv preprint arXiv:1805.05388*.

Pennington, J., Socher, R., & Manning, C. D. (2014). Glove: Global vectors for word representation. In Proceedings of the 2014 conference on empirical methods in natural language processing (EMNLP) (pp. 1532-1543).

Rodríguez, P. L. (2023, August 4). *conText - Quick Start Guide*. GitHub. <https://github.com/prodriguezsosa/conText/blob/master/vignettes/quickstart.md>

Rodriguez, P. L., Spirling, A., & Stewart, B. M. (2023). Embedding Regression: Models for Context-Specific Description and Inference. American Political Science Review, 117(4), 1255–1274. <doi:10.1017/S0003055422001228>

Schoenfeld, M., Eckhard, S., Patz, R., Meegdenburg, H. van, & Pires, A. (2019). The UN Security Council Debates (Version V5) [Data set]. Harvard Dataverse. <https://doi.org/10.7910/DVN/KGVSYH>
