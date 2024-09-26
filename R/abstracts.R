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
