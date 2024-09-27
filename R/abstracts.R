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
  
  response <- POST(url=url, 
                   body = toJSON(query,auto_unbox=TRUE), 
                   encode = "json", 
                   query = list(scroll = '1m', size = 50),
                   add_headers("Content-Type" = "application/json")
                  )
  
  results <- fromJSON(content(response, "text", encoding = "UTF-8"),
                     httr::add_headers("Content-Type" = "application/json"))
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
