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
    syn = syn,
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
