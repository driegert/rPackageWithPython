#' Add two numbers using Python
#'
#' This function uses a Python backend to add two numbers.
#'
#' @param a A numeric value
#' @param b A numeric value
#'
#' @return The sum of a and b
#' @export
#'
#' @examples
#' py_add_wrapper(2, 3)
#' @importFrom reticulate py
#' @export
py_add_wrapper <- function(a, b){
  check_python_env_exists()

  result <- py$add_numbers(a, b)

  return(result)
}
