# RelMineR

In natural language processing (NLP) and text mining, understanding the relationship between two terms can be crucial for tasks such as knowledge extraction, semantic analysis, and information retrieval. For example, you may want to evaluate how strongly two concepts (such as "Cancer" and "TP53") are related across a large corpus of documents by considering their synonyms. This relationship can be quantified by calculating co-occurrences, Pointwise Mutual Information (PMI), and Normalized Pointwise Mutual Information (NPMI). 


**RelMineR** is an R package designed to facilitate the discovery of potential biomedical relationships between terms using PMI and NPMI scores. 

**Key Features:**

* **Relationship Quantification:** Employs established metrics like co-occurrences, PMI, and NPMI to measure the strength of relationships between terms.
* **PubMed Abstraction:** Leverages a pre-built Elasticsearch index of PubMed abstracts to efficiently search for relevant information.
* **Biomedical Focus:** Tailored to the specific needs of biomedical research, ensuring accurate and meaningful relationship discovery.

**How it Works:**

1. **Elasticsearch Integration:** RelMineR seamlessly connects to a pre-configured Elasticsearch index containing PubMed abstracts.
3. **Relationship Quantification:** Calculates metrics such as PMI and NPMI to quantify the strength of these relationships.
4. **API Access:** Provides a user-friendly API that allows researchers to query the system for potential relationships between terms of interest.

**Note:** Detailed instructions for building the Elasticsearch index of PubMed abstracts will be available in a separate GitHub repository.

By utilizing RelMineR, researchers can gain valuable insights into the connections between biomedical concepts, accelerating their understanding of complex biological processes and facilitating the discovery of new knowledge.


# Background

## Pointwise Mutual Information (PMI)

PMI is a measure of the association between two terms based on their co-occurrence. It quantifies how much more likely two terms are to co-occur than would be expected by chance. PMI is used widely in the field of information theory and computational linguistics to quantify the strength of association between two terms. It was initially proposed by [Church and Hanks (1990)](https://aclanthology.org/J90-1003.pdf) as a way to measure word associations in corpora.

$$
\text{PMI}(A, B) = \log \frac{P(A, B)}{P(A) \cdot P(B)}
$$

Where:
- \( P(A, B) \) is the probability that both terms \(A\) and \(B\) occur together (co-occurrence).
- \( P(A) \) is the probability that term \(A\) occurs.
- \( P(B) \) is the probability that term \(B\) occurs.

## PMI in Terms of Document Counts

When working with document counts in a corpus, PMI can be expressed as:

$$
\text{PMI}(A, B) = \log \frac{\frac{n_{AB}}{N}}{\left(\frac{n_A}{N}\right) \cdot \left(\frac{n_B}{N}\right)}
$$

Where:
- \(n_{AB}\) is the number of documents where both \(A\) and \(B\) occur (co-occurrence).
- \(n_A\) is the number of documents where \(A\) occurs.
- \(n_B\) is the number of documents where \(B\) occurs.
- \(N\) is the total number of documents.

## Normalized Pointwise Mutual Information (nPMI)

nPMI is a normalized version of PMI that scales the values between -1 and 1. It is used to account for the fact that PMI tends to increase with rarer terms. It was first implemented by [Bouma (2009)](https://www.semanticscholar.org/paper/Normalized-(pointwise)-mutual-information-in-Bouma/15218d9c029cbb903ae7c729b2c644c24994c201). 


$$
\text{nPMI}(A, B) = \frac{\text{PMI}(A, B)}{-\log P(A, B)}
$$

Or in terms of document counts:

$$
\text{nPMI}(A, B) = \frac{\log \frac{P(A, B)}{P(A) \cdot P(B)}}{-\log P(A, B)}
$$

Where:
- \(P(A, B)\) is the probability of co-occurrence of \(A\) and \(B\), as defined above.

## Additional Notes:

- PMI is positive if the two terms co-occur more often than expected by chance, negative if they co-occur less often, and zero if they are independent.
- nPMI normalizes PMI and ranges from -1 to 1, where:
  - \(1\) indicates perfect co-occurrence (always occur together).
  - \(0\) indicates independence (no association).
  - \(-1\) indicates that the terms never co-occur.


## Select application to biomedical research 

### Stress response pathways
[Chambers et al. (2024)](https://doi.org/10.1021/acs.chemrestox.3c00335.) have used the approach to find chemicals that induce adaptive stress response pathways (SRPs) by applying Pointwise Mutual Information (PMI) and Normalized Pointwise Mutual Information (NPMI), as described in Chambers et al. (2024). SRPs are essential for restoring cellular homeostasis following perturbation, and when disrupted beyond critical thresholds, they can lead to apoptosis, autophagy, or cellular senescence. These pathways are key indicators for therapeutic interventions and biomarkers of toxicity.

## References

[Church, Kenneth, and Patrick Hanks. “Word Association Norms, Mutual Information, and Lexicography.” Computational Linguistics 16, no. 1 (1990): 22–29.](https://aclanthology.org/J90-1003.pdf)

[Bouma, Gerlof. “Normalized (Pointwise) Mutual Information in Collocation Extraction.” Proceedings of GSCL 30 (2009): 31–40.](https://www.semanticscholar.org/paper/Normalized-(pointwise)-mutual-information-in-Bouma/15218d9c029cbb903ae7c729b2c644c24994c201)

[Chambers, Bryant A., Danilo Basili, Laura Word, Nancy Baker, Alistair Middleton, Richard S. Judson, and Imran Shah. “Searching for LINCS to Stress: Using Text Mining to Automate Reference Chemical Curation.” Chemical Research in Toxicology 37, no. 6 (June 17, 2024): 878–93.](https://doi.org/10.1021/acs.chemrestox.3c00335.)

## Installation

You can install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("https://github.com/i-shah/relminer.git")
