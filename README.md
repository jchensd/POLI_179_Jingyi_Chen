## Comparative Analysis of Countries' Perspectives on 'Rule of Law' in the U.N. Security Council Debates Leveraging the conText Embedding Regression

### Group

![]()Jingyi Chen (A17519136)

### Introduction

In this project, I applied the conText Embedding Regression method introduced by Rodriguez et al. (2023) to compare the contextual meanings of "rule of law" in the United Nations Security Council debates across different countries. The "conText" package developed by Rodriguez et al. (2023) was used to conduct analysis in R.

### Data

#### Overview

The main data analyzed in this project is the United Nations Security Council debates from Harvard Dataverse (Schoenfeld et al., 2019). The filtered data include 8435 speeches that mentioned "rule of law" from April 1995 to November 2020 and their document IDs, as well as the covariates like country, speaker, date, and topic.

#### Data Preprocessing

The original dataset from Schoenfeld et al. (2019) consists of two files: "docs_meta.RData" and "docs.RData", which were merged using the shared document IDs. Because the primary objective of this project is to examine how the phrase "rule of law" is used by different countries in their U.N. Security Council speeches, it was made into one term, i.e. "ruleoflaw", which is the targeted/focal term in the analysis. Also, because I am also interested in whether some countries are more likely to associated "human rights" with "ruleoflaw", the former phrase is also made into one term, i.e. "humanrights". The whole dataset of speeches were filtered into only those that mentioned "ruleoflaw". In the meantime, I also compute the proportion of speeches that mentioned "ruleoflaw" among all speeches in a given year year and the below histogram illustrates the results:

![Image 1: Proportions of U.N. Security Council Speeches Mentioning 'rule of law' by Year](https://github.com/jchensd/POLI_179_Jingyi_Chen/assets/169096479/2e72ba6c-7540-4a3a-b6a6-af5afb57365f)

Then, I converted the column of texts into a corpus and tokens. I also conducted common text pre-processing using the "quanteda" package, including removing punctuation, symbols, numbers, separators, English stopwords, words with 2 or fewer characters and words appearing less than 5 times in the corpus (I used "padding=TRUE" to leave an empty string where the removed tokens previously existed), and converting words to lower case.

### Methods

#### 1. à la carte (ALC) Embeddings

In order to examine the contextual meanings of "ruleoflaw" by analyzing the words surrounding this targeted term, I collected 6 words before and after every instance in which "ruleoflaw" was mentioned among the speeches as well as the metadata associated with the instance. A document feature matrix was built, where thr rows (documents) consist of 6 words before and after 13837 instances of "ruleoflaw".

Then, I estimated GloVe embeddings from the 8435 filtered U.N. Security Council speeches using the "text2vec" package. A transform matrix (Matrix A) was computed using the "compute_transform" function in the "conText" package. The transform matrix helps weight the common, uninformative words lower in the embeddings.

The ALC embeddings method estimates the embeddings of the targeted word in a specific context by taking the average of the embeddings of words surrounding this word (e.g. 6 words before and after the targeted word) (Khodak et al., 2018). I obtained the embeddings of the words surrounding the 13837 instances of "ruleoflaw" from the GloVe model estimated previously and applied the transform matrix to construct a document-embedding matrix which contains the embeddings of words surrounding every instance of "ruleoflaw". Then, I took the column average of these embeddings to get the context-specific embeddings for "ruleoflaw".

With the locally trained GloVe embeddings, I found nearest neighbor words for the context-specific "ruleoflaw" embeddings. cosine similarity between each country's embedding and a specific set of featurescosine similarity between each country's embedding and a specific set of featurescosine similarity between each country's embedding and a specific set of featurescosine similarity between each country's embedding and a specific set of featurescosine similarity between each country's embedding and a specific set of featurescosine similarity between each country's embedding and a specific set of features.

#### 2. conText Embedding Regression

Using the conText regression model in the "conText" package, I regressed the embeddings of "ruleoflaw" over country. Before doing so, I removed the speeches by NGOs from the dataset and only included the 7103 speeches by countries (primarily because the full dataset was so big that the computer could not compute the regression). In this case, since there are multiple countries in the country variable, the model made them into dummy variables. This means that, for example, the variable "country_China" takes the value of 1 when the instance of "ruleoflaw" is from a speech by China and takes the value of 0 otherwise.

After constructing the regression, I obtained the embeddings for each country estimated by the regression

### Results

#### Nearest Neighbors Based on ALC Embeddings

The following is the nearest neighbors for the overall "ruleoflaw" embeddings from the whole corpus (i.e. 8435 U.N. Security Council speeches that mentioned "ruleoflaw"):

| feature       | rank | value     |
|:--------------|:-----|:----------|
| ruleoflaw     | 1    | 0.9355679 |
| strengthening | 2    | 0.8397012 |
| respect       | 3    | 0.7969343 |
| essential     | 4    | 0.7895955 |
| governance    | 5    | 0.7894433 |
| institutions  | 6    | 0.7815149 |
| humanrights   | 7    | 0.7773125 |
| promoting     | 8    | 0.7600160 |
| ensuring      | 9    | 0.7440357 |
| justice       | 10   | 0.7420294 |
| fundamental   | 11   | 0.7406022 |
| crucial       | 12   | 0.7170282 |
| strengthen    | 13   | 0.7144370 |
| democracy     | 14   | 0.7141022 |
| promote       | 15   | 0.7099270 |

The nearest neighbor features for the specific context of China and the U.S.:

| **target** | **feature**    | **rank** | **value** |
|:-----------|:---------------|:---------|:----------|
| China      | ruleoflaw      | 1        | 0.8319575 |
| China      | stability      | 2        | 0.7922305 |
| China      | strengthening  | 3        | 0.7720376 |
| China      | essential      | 4        | 0.7560088 |
| China      | development    | 5        | 0.7473085 |
| China      | institutions   | 6        | 0.7404832 |
| China      | strengthen     | 7        | 0.7293786 |
| China      | order          | 8        | 0.7277251 |
| China      | promote        | 9        | 0.7177649 |
| China      | respect        | 10       | 0.7080535 |
| China      | promoting      | 11       | 0.7021248 |
| China      | efforts        | 12       | 0.6981863 |
| China      | believe        | 13       | 0.6891291 |
| China      | economic       | 14       | 0.6867516 |
| China      | reconciliation | 15       | 0.6819550 |

| **target**               | **feature**   | **rank** | **value** |
|:-------------------------|:--------------|:---------|:----------|
| United States Of America | ruleoflaw     | 1        | 0.8884702 |
| United States Of America | institutions  | 2        | 0.8056607 |
| United States Of America | strengthening | 3        | 0.7781048 |
| United States Of America | governance    | 4        | 0.7569486 |
| United States Of America | strengthen    | 5        | 0.7556756 |
| United States Of America | essential     | 6        | 0.7404571 |
| United States Of America | respect       | 7        | 0.7394818 |
| United States Of America | promote       | 8        | 0.7198265 |
| United States Of America | humanrights   | 9        | 0.7154944 |
| United States Of America | democracy     | 10       | 0.7013341 |
| United States Of America | promoting     | 11       | 0.6887101 |
| United States Of America | order         | 12       | 0.6816403 |
| United States Of America | building      | 13       | 0.6790501 |
| United States Of America | ensuring      | 14       | 0.6768293 |
| United States Of America | stability     | 15       | 0.6765675 |

The following table displays the ratios of cosine similarities. First, it computed the cosine similarities between the embeddings of "ruleoflaw" and the features for China's and the U.S.'s contexts. Then, it takes the ratio of cosine similarities for the two countries. This means that that the features with values larger than 1 are more associated with "ruleoflaw" in China's context compared to the U.S.'s context; features with values smaller than 1 are more associated with "ruleoflaw" in the U.S.'s context compared to China's context.

|        | **feature**   | **value** |
|:-------|:--------------|:----------|
| **1**  | stability     | 1.1709556 |
| **2**  | development   | 1.1569086 |
| **3**  | order         | 1.0676088 |
| **4**  | essential     | 1.0210028 |
| **5**  | promote       | 0.9971360 |
| **6**  | strengthening | 0.9922026 |
| **7**  | strengthen    | 0.9652008 |
| **8**  | respect       | 0.9574996 |
| **9**  | democracy     | 0.9442226 |
| **10** | ruleoflaw     | 0.9363932 |
| **11** | institutions  | 0.9191006 |
| **12** | governance    | 0.8987647 |
| **13** | humanrights   | 0.8458819 |

#### conText Embedding Regression Results

The following is the nearest neighbor features for the intercept embeddings of "ruleoflaw" as estimated by the regression:

| **intercept_wv.feature** | **intercept_wv.rank** | **intercept_wv.value** |
|:-------------------------|:----------------------|:-----------------------|
| governance               | 1                     | 0.8575313              |
| ruleoflaw                | 2                     | 0.7724213              |
| strengthening            | 3                     | 0.7292756              |
| democracy                | 4                     | 0.7177035              |
| promoting                | 5                     | 0.7071556              |
| humanrights              | 6                     | 0.7011513              |
| respect                  | 7                     | 0.6573512              |
| rights                   | 8                     | 0.6560221              |
| institutions             | 9                     | 0.6546322              |
| fundamental              | 10                    | 0.6543437              |
| promotion                | 11                    | 0.6488464              |
| ensuring                 | 12                    | 0.6443824              |
| development              | 13                    | 0.6414632              |
| essential                | 14                    | 0.6331904              |
| good                     | 15                    | 0.6321306              |

The following is the regression outputs for China and the U.S.:

| **country**                      | **normed_estimate** | **std_error** | **lower_ci** | **upper_ci** | **p_value** |
|:---------------------------------|:--------------------|:--------------|:-------------|:-------------|:------------|
| country_China                    | 1.697853            | 0.1479866     | 1.407774     | 1.987932     | 0           |
| country_United States Of America | 1.430671            | 0.1627434     | 1.111666     | 1.749675     | 0           |

The following is the nearest neighbor features for the embeddings of "ruleoflaw" in China's context as estimated by the regression:

| **China_wv.feature** | **China_wv.rank** | **China_wv.value** |
|:---------------------|:------------------|:-------------------|
| ruleoflaw            | 1                 | 0.8320788          |
| stability            | 2                 | 0.7915291          |
| strengthening        | 3                 | 0.7722771          |
| essential            | 4                 | 0.7558402          |
| development          | 5                 | 0.7470143          |
| institutions         | 6                 | 0.7401886          |
| strengthen           | 7                 | 0.7289622          |
| order                | 8                 | 0.7268133          |
| promote              | 9                 | 0.7171448          |
| respect              | 10                | 0.7078517          |
| promoting            | 11                | 0.7022481          |
| efforts              | 12                | 0.6973016          |
| believe              | 13                | 0.6886376          |
| economic             | 14                | 0.6861399          |
| reconciliation       | 15                | 0.6813317          |

The following is the nearest neighbor features for the embeddings of "ruleoflaw" in the U.S.'s context as estimated by the regression:

| **US_wv.feature** | **US_wv.rank** | **US_wv.value** |
|:------------------|:---------------|:----------------|
| ruleoflaw         | 1              | 0.8883046       |
| institutions      | 2              | 0.8054595       |
| strengthening     | 3              | 0.7776455       |
| governance        | 4              | 0.7571846       |
| strengthen        | 5              | 0.7552568       |
| essential         | 6              | 0.7400785       |
| respect           | 7              | 0.7391297       |
| promote           | 8              | 0.7200812       |
| humanrights       | 9              | 0.7151871       |
| democracy         | 10             | 0.7014251       |
| promoting         | 11             | 0.6889003       |
| order             | 12             | 0.6814194       |
| building          | 13             | 0.6788800       |
| stability         | 14             | 0.6768726       |
| ensuring          | 15             | 0.6766737       |

The following table displays the ratios of cosine similarities based on embeddings estimated by the regression. As stated in the previous section, it means that that the features with values larger than 1 are more associated with "ruleoflaw" in China's context compared to the U.S.'s context; features with values smaller than 1 are more associated with "ruleoflaw" in the U.S.'s context compared to China's context. It is very similar the results based on the ALC embeddings in the previous section with slightly different values.

|        | **feature**   | **value** |
|:-------|:--------------|:----------|
| **1**  | stability     | 1.1693916 |
| **2**  | development   | 1.1564117 |
| **3**  | order         | 1.0666166 |
| **4**  | essential     | 1.0212973 |
| **5**  | promote       | 0.9959222 |
| **6**  | strengthening | 0.9930966 |
| **7**  | strengthen    | 0.9651846 |
| **8**  | respect       | 0.9576827 |
| **9**  | democracy     | 0.9439583 |
| **10** | ruleoflaw     | 0.9367043 |
| **11** | institutions  | 0.9189645 |
| **12** | governance    | 0.8988757 |
| **13** | humanrights   | 0.8456848 |

### Discussions

### References

Khodak, M., Saunshi, N., Liang, Y., Ma, T., Stewart, B., & Arora, S. (2018). A la carte embedding: Cheap but effective induction of semantic feature vectors. *arXiv preprint arXiv:1805.05388*.

Pennington, J., Socher, R., & Manning, C. D. (2014). Glove: Global vectors for word representation. In Proceedings of the 2014 conference on empirical methods in natural language processing (EMNLP) (pp. 1532-1543).

Rodriguez, P. L., Spirling, A., & Stewart, B. M. (2023). Embedding Regression: Models for Context-Specific Description and Inference. American Political Science Review, 117(4), 1255–1274. <doi:10.1017/S0003055422001228>

Schoenfeld, M., Eckhard, S., Patz, R., Meegdenburg, H. van, & Pires, A. (2019). The UN Security Council Debates (Version V5) [Data set]. Harvard Dataverse. <https://doi.org/10.7910/DVN/KGVSYH>
