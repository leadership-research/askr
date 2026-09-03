#' Pretty print for askr_response objects
#'
#' Prints a summary of an `askr_response`. The response text is truncated at
#' `max_chars` characters by default to avoid inadvertently printing large
#' volumes of model output (which may contain rephrased participant data) to
#' shared console sessions or log sinks.
#'
#' Set `max_chars = Inf` to print the full response.
#'
#' @param x An object of class "askr_response" (returned by `ask_raw()`).
#' @param max_chars Integer scalar. Maximum number of characters of the response
#'   text to print. Default 500. Set to `Inf` to disable truncation.
#' @param ... Ignored.
#'
#' @export
print.askr_response <- function(x, max_chars = 500L, ...) {
  cat("askr_response\n")
  cat("  ok:     ", x$ok,     "\n", sep = "")
  cat("  status: ", x$status, "\n", sep = "")
  cat("  model:  ", x$model,  "\n", sep = "")
  cat("  text:\n")

  txt <- if (!is.null(x$response)) x$response else "<NULL>"
  if (is.finite(max_chars) && nchar(txt) > max_chars) {
    txt <- paste0(substr(txt, 1L, max_chars), "\n  ... [truncated — use max_chars = Inf to see full response]")
  }
  cat(txt, "\n", sep = "")
  invisible(x)
}
