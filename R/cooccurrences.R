

#' Calculate PMI and NPMI for co-occurrences
#'
#' @param A A term list containing the name, synonyms, and class for entity A.
#' @param B A term list containing the name, synonyms, and class for entity B.
#' @param index_name Name of the Elasticsearch index.
#' @param relminer The RelMiner object.
#' @return A data frame with co-occurrence counts, PMI, and NPMI values.
#' @export
find_cooccurrences <- function(A, B, index_name, relminer) {
  na <- count_occurrences(A$syn, index_name, relminer)
  nb <- count_occurrences(B$syn, index_name, relminer)
  n_ab <- count_cooccurrences(A$syn, B$syn, index_name, relminer)
  total_docs <- count_occurrences(c(""), index_name, relminer) # Total document count
  
  pmi <- if (n_ab > 0) log((n_ab * total_docs) / (na * nb)) else 0
  npmi <- if (n_ab > 0) pmi / -log(n_ab / total_docs) else 0
  
  data.frame(
    term_a = A$name,
    term_b = B$name,
    class_a = A$class,
    class_b = B$class,
    count_a = na,
    count_b = nb,
    count_ab = n_ab,
    pmi = pmi,
    npmi = npmi
  )
}

#' Count co-occurrences of two sets of terms
#'
#' @param terms_A List of terms for entity A.
#' @param terms_B List of terms for entity B.
#' @param index_name Name of the Elasticsearch index.
#' @param relminer The RelMiner object.
#' @return The count of co-occurrences.
#' @export
count_cooccurrences <- function(terms_A, terms_B, index_name, relminer) {
  query <- build_cooccurrence_query(terms_A, terms_B)
  url <- paste0(relminer$es_url, "/", index_name, "/_count")
  response <- POST(url, body = toJSON(query), encode = "json")
  content <- fromJSON(content(response, "text", encoding = "UTF-8"))
  content$count
}
    
#' Build a co-occurrence query
#'
#' @param terms_A List of terms for entity A.
#' @param terms_B List of terms for entity B.
#' @return A query list for Elasticsearch.
#' @export
build_cooccurrence_query <- function(terms_A, terms_B) {
  list(
    query = list(
      bool = list(
        must = list(
          list(bool = list(should = lapply(terms_A, function(term) list(match_phrase = list(abstract = term))))),
          list(bool = list(should = lapply(terms_B, function(term) list(match_phrase = list(abstract = term)))))
        )
      )
    )
  )
}
                           

#' Function to run find_cooccurrences in parallel
#'
#' @param A A term list containing the name, synonyms, and class for entity A.
#' @param B A term list containing the name, synonyms, and class for entity B.
#' @param index_name Name of the Elasticsearch index.
#' @param relminer The RelMiner object.
#' @param n_jobs the number of jobs to run in parallel.    
#' @return A data frame with co-occurrence counts, PMI, and NPMI values.
#' @export

run_cooccurrences_in_parallel <- function(terms_a, terms_b, index_name, relminer,n_jobs=10) {
  # Create a function that takes two terms and runs find_cooccurrences
  cooccurrence_func <- function(A, B) {
    find_cooccurrences(A, B, index_name, relminer)
  }

   available_cores <- detectCores()
  
  # Ensure n_jobs does not exceed the number of available cores
  if (n_jobs > available_cores) {
    n_jobs <- available_cores - 1
  }
  
  # Prepare combinations of terms_a and terms_b
  combinations <- expand.grid(terms_a = seq_along(terms_a), terms_b = seq_along(terms_b))

  # Use mclapply to run cooccurrences in parallel
  results_list <- mclapply(seq_len(nrow(combinations)), function(i) {
    A <- terms_a[[combinations$terms_a[i]]]
    B <- terms_b[[combinations$terms_b[i]]]
    cooccurrence_func(A, B)
  }, mc.cores = n_jobs) # Use all but one core

  # Combine all results into a single data frame
  results_df <- do.call(rbind, results_list)
  
  # Return the final data frame
  return(results_df)
}

    