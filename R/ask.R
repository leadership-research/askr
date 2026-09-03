#' High-level helper for analysts / researchers
#'
#' `ask()` is the convenience wrapper for humans. It calls `ask_raw()` and
#' returns just the model text, or a readable error string. It does not `stop()`
#' on HTTP errors, which makes it nicer in interactive use.
#'
#' @param prompt Character scalar. The question / instruction you want to send.
#' @param model Character scalar. Alias or engine from the registry.
#' @param temperature Numeric scalar. Optional sampling temperature. Default 0.7.
#' @param system_prompt Character scalar. System-level instruction. See
#'   [ask_raw()] for details.
#' @param extra_params Named list of additional API body parameters. See
#'   [ask_raw()] for details.
#'
#' @return Character scalar. The model-generated text on success. On failure,
#' returns a string beginning with "ask() error:" describing the issue.
#'
#' @examples
#' \dontrun{
#' Sys.setenv(API_KEY = "your-azure-token")
#' ask(
#'   prompt = "Extract 3 leadership risks from this transcript.",
#'   model = "mistral",
#'   temperature = 0.4
#' )
#' }
#'
#' @export
ask <- function(prompt, model, temperature = 0.7,
                system_prompt = "You are a helpful AI assistant.",
                extra_params  = list()) {
  if (missing(prompt) || length(prompt) != 1L ||
      is.na(prompt) || !nzchar(prompt)) {
    stop("ask(): `prompt` must be a non-empty string.", call. = FALSE)
  }

  raw <- ask_raw(
    query         = prompt,
    model         = model,
    temperature   = temperature,
    system_prompt = system_prompt,
    extra_params  = extra_params
  )
  
  if (isTRUE(raw$ok)) {
    raw$response
  } else {
    paste0(
      "[ask() error] status=", raw$status,
      " model=", raw$model,
      " message=", raw$response
    )
  }
}
