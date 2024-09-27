#' Find sentences with co-occurrences of A and B
#'
#' @param A A term list containing the name, synonyms, and class for entity A.
#' @param B A term list containing the name, synonyms, and class for entity B.
#' @param index_name Name of the Elasticsearch index.
#' @param relminer The RelMiner object.
#' @return A data frame with sentences containing co-occurrences of A and B.
#' @export
find_sentences_with_cooccurrences <- function(A, B, relminer) {
  abstracts <- find_abstracts(A, B, relminer$es_index, relminer)
  rx_a <- paste(A$syn, collapse = "|")
  rx_b <- paste(B$syn, collapse = "|")
  
  matching_sentences <- data.frame()
  
  for (i in seq_len(nrow(abstracts))) {
    sentences <- tokenize_sentences(abstracts$abstract[i])[[1]]
    for (sentence in sentences) {
      if (str_detect(sentence, regex(rx_a, ignore_case = TRUE)) &&
          str_detect(sentence, regex(rx_b, ignore_case = TRUE))) {
        matching_sentences <- rbind(matching_sentences, data.frame(
          pmid = abstracts$pmid[i],
          title = abstracts$title[i],
          sentence = sentence
        ))
      }
    }
  }
  
  matching_sentences
}
