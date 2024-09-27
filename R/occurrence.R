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
    