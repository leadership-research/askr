#' Resolve a model alias/engine to its deployment metadata
#'
#' askr lets you refer to models using either a friendly alias (e.g. "gpt-4o")
#' or the raw deployment/engine string. This function normalizes that and
#' returns the info required to make an API call.
#'
#' Only models marked `enabled == TRUE` in the registry are considered valid.
#'
#' @param model_name Character scalar. Model alias or engine name.
#'
#' @return
#' A list with elements:
#' \describe{
#'   \item{engine}{Character. Deployment/model identifier to send in the body.}
#'   \item{provider}{Character. "openai" or something else (e.g. "oss").}
#' }
#'
#' @keywords internal
resolve_model_info <- function(model_name) {
  if (missing(model_name) || length(model_name) != 1L ||
      is.na(model_name) || !nzchar(model_name)) {
    stop("resolve_model_info(): `model_name` must be a non-empty string.", call. = FALSE)
  }
  
  reg <- load_model_registry()
  
  # only enabled models are callable
  enabled <- reg[!is.na(reg$enabled) & reg$enabled, , drop = FALSE]
  if (nrow(enabled) == 0L) {
    stop(
      "No models are enabled in the registry. ",
      "Enable at least one model before calling ask()/ask_raw().",
      call. = FALSE
    )
  }
  
  key <- tolower(model_name)
  
  hit <- which(tolower(enabled$alias) == key)
  if (length(hit) == 0L) {
    hit <- which(tolower(enabled$engine) == key)
  }
  
  if (length(hit) != 1L) {
    stop(
      paste0(
        "Model '", model_name, "' not found among enabled models.\n",
        "Enabled aliases are: ",
        paste(enabled$alias, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  
  list(
    engine   = enabled$engine[[hit]],
    provider = enabled$provider[[hit]]
  )
}

#' Convenience alias that returns only the engine string
#'
#' Calls [resolve_model_info()] and returns just the engine name.
#' Useful when only the deployment identifier is needed.
#'
#' @inheritParams resolve_model_info
#' @return Character scalar, the model engine.
#'
#' @keywords internal
resolve_model <- function(model_name) {
  info <- resolve_model_info(model_name)
  info$engine
}
