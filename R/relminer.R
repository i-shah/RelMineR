#' Create a new RelMiner object
#'
#' @param host The Elasticsearch host URL (default: localhost).
#' @param port The Elasticsearch port (default: 9200).
#' @param user Elasticsearch username (default: NULL).
#' @param passwd Elasticsearch password (default: NULL).
#' @param rels A named list of relationships and their corresponding actions.
#' @return A list representing the RelMiner object.
#' @export
create_relminer <- function(host = 'localhost', port = 9200, user = NULL, passwd = NULL, rels = NULL) {
  es_url <- sprintf("http://%s:%s@%s:%d", user, passwd, host, port)
  rels_rx <- if (!is.null(rels)) paste(names(rels), collapse = "|") else NULL
  
  list(
    es_url = es_url,
    rels = rels,
    rels_rx = rels_rx
  )
}
