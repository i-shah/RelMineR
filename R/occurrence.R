#' Count occurrences of a list of terms in an Elasticsearch index
#' 
#' @param terms List of terms to search for.
#' @param index_name Name of the Elasticsearch index.
#' @param relminer The RelMiner object.
#' @return The count of occurrences.
#' @export
count_occurrences <- function(terms, index_name, relminer) {
  query <- list(
    query = list(
      bool = list(
        should = lapply(terms, function(term) list(match_phrase = list(abstract = term)))
      )
    )
  )
  url <- paste0(relminer$es_url, "/", index_name, "/_count")
  response <- POST(url, body = toJSON(query), encode = "json")
  content <- fromJSON(content(response, "text", encoding = "UTF-8"))
  content$count
}
    