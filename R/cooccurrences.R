

#' Calculate PMI and NPMI for co-occurrences
#'
#' @param A A term list containing the name, synonyms, and class for entity A.
#' @param B A term list containing the name, synonyms, and class for entity B.
#' @param relminer The RelMiner object.
#' @return A data frame with co-occurrence counts, PMI, and NPMI values.
#' @export
find_rel <- function(A, B, relminer) {
  na <- count_occurrences(A$synonyms,relminer)
  nb <- count_occurrences(B$synonyms,relminer)
  n_ab <- count_cooccurrences(A$synonyms, B$synonyms,relminer)
  total_docs <- count_all_docs(relminer) 

  pmi <- ifelse(n_ab > 0, log2(as.numeric(n_ab) * as.numeric(total_docs) / (as.numeric(na) * as.numeric(nb))), 0)
  npmi <- ifelse(n_ab > 0, pmi / -log2(as.numeric(n_ab) / as.numeric(total_docs)), 0)
  
  data.frame(
    term_a = A$name,
    term_b = B$name,
    class_a = A$class,
    class_b = B$class,
    count_a = na,
    count_b = nb,
    count_ab = n_ab,
    count_docs=total_docs,
    pmi = pmi,
    npmi = npmi
  )
}

#' Count co-occurrences of two sets of terms
#'
#' @param terms_A List of terms for entity A.
#' @param terms_B List of terms for entity B.
#' @param relminer The RelMiner object.
#' @return The count of co-occurrences.
#' @export
count_cooccurrences <- function(terms_A, terms_B, relminer) {
  query <- build_cooccurrence_query(terms_A, terms_B)

  url <- paste0(relminer$es_url, "/", relminer$es_index, "/_count")
  response <- POST(
      url = url,
      body = toJSON(query, auto_unbox = TRUE),
      encode = "json",
      add_headers("Content-Type" = "application/json")
    )
  content <- fromJSON(content(response, "text", encoding = "UTF-8"),
                     httr::add_headers("Content-Type" = "application/json"))
  content$count
}

#' Count documents in index
#'
#' @param relminer The RelMiner object.
#' @return The count of co-occurrences.
#' @export
count_all_docs <- function(relminer) {

  url <- paste0(relminer$es_url, "/", relminer$es_index, "/_count")
  response <- POST(
      url = url,
      encode = "json",
      add_headers("Content-Type" = "application/json")
    )
  content <- fromJSON(content(response, "text", encoding = "UTF-8"),
                     httr::add_headers("Content-Type" = "application/json"))
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
                           

#' Function to run find_rel in parallel
#'
#' @param A A term list containing the name, synonyms, and class for entity A.
#' @param B A term list containing the name, synonyms, and class for entity B.
#' @param relminer The RelMiner object.
#' @param n_jobs the number of jobs to run in parallel.    
#' @return A data frame with co-occurrence counts, PMI, and NPMI values.
#' @export

# find_rels <- function(terms_a, terms_b, relminer) {
#   Res = list()
#   for (A in terms_a){
#     for (B in terms_b){     
#       R <- find_rel(A, B,relminer)
#       Res <- c(Res,R)
#       }
#     }

#   return(Res)
#   # Combine all results into a single data frame
#   results_df <- do.call(rbind, results_list)
  
#   # Return the final data frame
#   results_df
# }

find_rels <- function(terms_a, terms_b, relminer) {
  
  # Prepare combinations of terms_a and terms_b
  combinations <- expand.grid(terms_a = seq_along(terms_a), terms_b = seq_along(terms_b))

  # Use mclapply to run cooccurrences in parallel
  results_list <- lapply(seq_len(nrow(combinations)), function(i) {
    A <- terms_a[[combinations$terms_a[i]]]
    B <- terms_b[[combinations$terms_b[i]]]
    find_rel(A, B,relminer)
  }) 

  # Combine all results into a single data frame
  results_df <- do.call(rbind, results_list)
  
  # Return the final data frame
  results_df
}

                           
                            
#' Function to run find_rel in parallel
#'
#' @param A A term list containing the name, synonyms, and class for entity A.
#' @param B A term list containing the name, synonyms, and class for entity B.
#' @param relminer The RelMiner object.
#' @param n_jobs the number of jobs to run in parallel.    
#' @return A data frame with co-occurrence counts, PMI, and NPMI values.
#' @export

find_rels_par <- function(terms_a, terms_b, relminer,n_jobs=10) {
  available_cores <- detectCores()
  n_jobs <- ifelse(  n_jobs > available_cores, available_cores-1,n_jobs)
  
  # Prepare combinations of terms_a and terms_b
  combinations <- expand.grid(terms_a = seq_along(terms_a), terms_b = seq_along(terms_b))

  # Use mclapply to run cooccurrences in parallel
  results_list <- mclapply(seq_len(nrow(combinations)), function(i) {
    A <- terms_a[[combinations$terms_a[i]]]
    B <- terms_b[[combinations$terms_b[i]]]
    find_rel(A, B,relminer)
  }, mc.cores = n_jobs) 

  # Combine all results into a single data frame
  results_df <- do.call(rbind, results_list)

  # Return the final data frame
  results_df
}

    