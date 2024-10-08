% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/relminer.R
\name{create_relminer}
\alias{create_relminer}
\title{Create a new RelMiner object}
\usage{
create_relminer(
  host = "localhost",
  port = 9200,
  user = NULL,
  passwd = NULL,
  rels = NULL,
  index = "pubmed"
)
}
\arguments{
\item{host}{The Elasticsearch host URL (default: localhost).}

\item{port}{The Elasticsearch port (default: 9200).}

\item{user}{Elasticsearch username (default: NULL).}

\item{passwd}{Elasticsearch password (default: NULL).}

\item{rels}{A named list of relationships and their corresponding actions.}

\item{index}{Elasticsearch index (default: pubmed).}
}
\value{
A list representing the RelMiner object.
}
\description{
Create a new RelMiner object
}
