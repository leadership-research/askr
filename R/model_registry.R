# Package-level registry cache — populated on first call, reused for the
# lifetime of the R session. Reset automatically when the package is reloaded.
# Tests that mock load_model_registry() bypass this cache entirely.
.registry_cache <- local({
  .cache <- NULL
  list(
    get   = function() .cache,
    set   = function(x) { .cache <<- x; x },
    clear = function() { .cache <<- NULL }
  )
})

#' Load the askr model registry
#'
#' Loads model definitions from the package's installed registry. Results are
#' cached in-session so repeated calls (e.g. in a batch loop) do not re-read
#' the JSON file from disk. The cache is cleared when the package is reloaded.
#'
#' The registry must contain, at minimum:
#' \itemize{
#'   \item alias     Character. Friendly handle for the model (e.g. "gpt-4o").
#'   \item engine    Character. The deployment/model identifier to send to Azure.
#'   \item provider  Character. "openai" for Azure OpenAI deployments, anything
#'                   else (e.g. "mistral", "oss", "meta") for OSS style.
#'   \item enabled   Logical or equivalent (TRUE/FALSE).
#' }
#'
#' @return
#' A data.frame with columns `alias`, `engine`, `provider`, `enabled`.
#' Only basic normalization is applied; content is otherwise trusted.
#'
#' @importFrom jsonlite fromJSON
#' @keywords internal
load_model_registry <- function() {
  cached <- .registry_cache$get()
  if (!is.null(cached)) return(cached)

  path <- system.file("config", "models.json", package = "askr")
  if (!file.exists(path)) {
    stop(
      "askr could not locate config/models.json in the installed package. ",
      "Ensure inst/config/models.json exists before installation.",
      call. = FALSE
    )
  }

  dat <- jsonlite::fromJSON(path, simplifyDataFrame = TRUE)

  required_cols <- c("alias", "engine", "provider", "enabled")
  missing_cols <- setdiff(required_cols, names(dat))
  if (length(missing_cols) > 0) {
    stop(
      "Model registry is missing required column(s): ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  dat$alias    <- as.character(dat$alias)
  dat$engine   <- as.character(dat$engine)
  dat$provider <- tolower(as.character(dat$provider))

  if (!is.logical(dat$enabled)) {
    lc <- tolower(as.character(dat$enabled))
    dat$enabled <- ifelse(
      lc %in% c("true", "t", "1", "yes", "y"),
      TRUE,
      ifelse(lc %in% c("false", "f", "0", "no", "n"), FALSE, NA)
    )
    dat$enabled <- as.logical(dat$enabled)
  }

  .registry_cache$set(dat)
}
