#' Pipe operator
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom purrr %>%
#' @usage lhs \%>\% rhs
NULL


if (getRversion() >= "2.15.1") utils::globalVariables(c(":="))

# environment to hold data about the Drive API
.googledocs <- new.env(parent = emptyenv())

# environment to store credentials
.state <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {

  .state[["app"]] <- gargle::tidyverse_app()
  .state[["api_key"]] <- gargle::tidyverse_api_key()

  set_auth_active(TRUE)
  set_api_key(.state[["api_key"]])
  set_oauth_app(.state[["app"]])

  invisible()
}
