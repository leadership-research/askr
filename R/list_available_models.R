#' List enabled model aliases
#'
#' Convenience helper for discoverability. Returns the aliases of all models
#' in the registry that are marked `enabled == TRUE`. These are the model names
#' you can pass to [ask()] or [ask_raw()].
#'
#' @return
#' Character vector of enabled model aliases. Returns `character(0)` if none.
#'
#' @examples
#' \dontrun{
#' list_available_models()
#' }
#'
#' @seealso [load_model_registry()], [ask()], [ask_raw()]
#' @export
list_available_models <- function() {
  reg <- load_model_registry()
  if (nrow(reg) == 0L) {
    message("No models found in registry.")
    return(character(0))
  }
  
  enabled <- reg[!is.na(reg$enabled) & reg$enabled, , drop = FALSE]
  if (nrow(enabled) == 0L) {
    message("No enabled models found in registry.")
    return(character(0))
  }
  
  alias <- enabled$alias
  alias[!nzchar(alias)] <- enabled$engine[!nzchar(alias)]
  alias
}
