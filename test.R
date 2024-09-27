#' @import httr
#' @import jsonlite
#' @import stringr
#' @import tokenizers
#' @import parallel
#' @importFrom httr POST
#' @importFrom jsonlite toJSON
#' @importFrom jsonlite fromJSON

NULL
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

    #' Create a term object
#' 
#' @param name The name of the term.
#' @param syn A list of synonyms for the term.
#' @param class The class/category of the term.
#' @return A list representing the term.
#' @export
create_term <- function(name, syn, class) {
  list(
    name = name,
    synonyms = syn,
    class = class
  )
}

# Function to create a list of terms from a data.frame
create_terms_list <- function(df) {
  # Initialize an empty list to store terms
  terms_list <- list()
  
  # Iterate over each row in the data frame
  for (i in seq_len(nrow(df))) {
    # Create a term using create_term function
    term <- create_term(
      name = df$entity_name[i],
      syn = df$terms[[i]],  # Access the list of synonyms
      class = df$entity_class[i]
    )
    
    # Add the term to the list
    terms_list[[i]] <- term
  }
  
  # Return the list of terms
  return(terms_list)
}
#' Count occurrences of a list of terms in an Elasticsearch index
#' 
#' @param terms List of terms to search for.
#' @param relminer The RelMiner object.
#' @return The count of occurrences.
#' @export
count_occurrences <- function(terms, relminer) {
  query <- list(
    query = list(
      bool = list(
        should = lapply(terms, function(term) list(match_phrase = list(abstract = term)))
      )
    )
  )
  
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
    #' Create a new RelMiner object
#'
#' @param host The Elasticsearch host URL (default: localhost).
#' @param port The Elasticsearch port (default: 9200).
#' @param user Elasticsearch username (default: NULL).
#' @param passwd Elasticsearch password (default: NULL).
#' @param index Elasticsearch index (default: pubmed).
#' @param rels A named list of relationships and their corresponding actions.
#' @return A list representing the RelMiner object.
#' @export
create_relminer <- function(host = 'localhost', port = 9200, user = NULL, passwd = NULL, rels = NULL, index='pubmed') {

  # Check if username and password are provided
  if (!is.null(user) && !is.null(passwd)) {
    # Construct the URL with authentication
    es_url <- sprintf("http://%s:%s@%s:%d", user, passwd, host, port)
  } else {
    # Construct the URL without authentication
    es_url <- sprintf("http://%s:%d", host, port)
  }
 
  rels_rx <- if (!is.null(rels)) paste(names(rels), collapse = "|") else NULL
  
  list(
    es_url = es_url,
    es_index=index,
    rels = rels,
    rels_rx = rels_rx
  )
}
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
#' Create a term object
#' 
#' @param name The name of the term.
#' @param syn A list of synonyms for the term.
#' @param class The class/category of the term.
#' @return A list representing the term.
#' @export
create_term <- function(name, syn, class) {
  list(
    name = name,
    synonyms = syn,
    class = class
  )
}

# Function to create a list of terms from a data.frame
create_terms_list <- function(df) {
  # Initialize an empty list to store terms
  terms_list <- list()
  
  # Iterate over each row in the data frame
  for (i in seq_len(nrow(df))) {
    # Create a term using create_term function
    term <- create_term(
      name = df$entity_name[i],
      syn = df$terms[[i]],  # Access the list of synonyms
      class = df$entity_class[i]
    )
    
    # Add the term to the list
    terms_list[[i]] <- term
  }
  
  # Return the list of terms
  return(terms_list)
}


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

    #' Count occurrences of a list of terms in an Elasticsearch index
#' 
#' @param terms List of terms to search for.
#' @param relminer The RelMiner object.
#' @return The count of occurrences.
#' @export
count_occurrences <- function(terms, relminer) {
  query <- list(
    query = list(
      bool = list(
        should = lapply(terms, function(term) list(match_phrase = list(abstract = term)))
      )
    )
  )
  
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
    #' @import httr
#' @import jsonlite
#' @import stringr
#' @import tokenizers
#' @import parallel
#' @importFrom httr POST
#' @importFrom jsonlite toJSON
#' @importFrom jsonlite fromJSON

NULL
#' Create a new RelMiner object
#'
#' @param host The Elasticsearch host URL (default: localhost).
#' @param port The Elasticsearch port (default: 9200).
#' @param user Elasticsearch username (default: NULL).
#' @param passwd Elasticsearch password (default: NULL).
#' @param index Elasticsearch index (default: pubmed).
#' @param rels A named list of relationships and their corresponding actions.
#' @return A list representing the RelMiner object.
#' @export
create_relminer <- function(host = 'localhost', port = 9200, user = NULL, passwd = NULL, rels = NULL, index='pubmed') {

  # Check if username and password are provided
  if (!is.null(user) && !is.null(passwd)) {
    # Construct the URL with authentication
    es_url <- sprintf("http://%s:%s@%s:%d", user, passwd, host, port)
  } else {
    # Construct the URL without authentication
    es_url <- sprintf("http://%s:%d", host, port)
  }
 
  rels_rx <- if (!is.null(rels)) paste(names(rels), collapse = "|") else NULL
  
  list(
    es_url = es_url,
    es_index=index,
    rels = rels,
    rels_rx = rels_rx
  )
}
#' Retrieve abstracts containing co-occurrences of entity A and B
#'
#' @param A A term list containing the name, synonyms, and class for entity A.
#' @param B A term list containing the name, synonyms, and class for entity B.
#' @param index_name Name of the Elasticsearch index.
#' @param relminer The RelMiner object.
#' @return A data frame of abstracts containing co-occurrences of A and B.
#' @export
find_abstracts <- function(A, B, index_name, relminer) {
  query <- build_cooccurrence_query(A$syn, B$syn)
  url <- paste0(relminer$es_url, "/", index_name, "/_search")
  
  response <- POST(url, body = toJSON(query), encode = "json", query = list(scroll = '1m', size = 50))
  results <- fromJSON(content(response, "text", encoding = "UTF-8"))
  scroll_id <- results$`_scroll_id`
  hits <- results$hits$hits
  
  abstracts <- lapply(hits, function(hit) {
    list(
      pmid = hit$`_source`$pmid,
      title = hit$`_source`$title,
      abstract = hit$`_source`$abstract
    )
  })
  
  data.frame(do.call(rbind, abstracts))
}
#' Retrieve abstracts containing co-occurrences of entity A and B
#'
#' @param A A term list containing the name, synonyms, and class for entity A.
#' @param B A term list containing the name, synonyms, and class for entity B.
#' @param relminer The RelMiner object.
#' @return A data frame of abstracts containing co-occurrences of A and B.
#' @export
find_abstracts <- function(A, B, relminer) {
  query <- build_cooccurrence_query(A$syn, B$syn)
  url <- paste0(relminer$es_url, "/", relminer$es_index, "/_search")
  
  response <- POST(url, body = toJSON(query), encode = "json", query = list(scroll = '1m', size = 50))
  results <- fromJSON(content(response, "text", encoding = "UTF-8"))
  scroll_id <- results$`_scroll_id`
  hits <- results$hits$hits
  
  abstracts <- lapply(hits, function(hit) {
    list(
      pmid = hit$`_source`$pmid,
      title = hit$`_source`$title,
      abstract = hit$`_source`$abstract
    )
  })
  
  data.frame(do.call(rbind, abstracts))
}
