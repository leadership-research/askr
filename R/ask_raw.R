#' Low-level LLM request (structured response)
#'
#' `ask_raw()` is the low-level interface to Azure AI Foundry. It is meant
#' for programmatic use when you want status codes, model info, etc.
#'
#' How it works:
#' \enumerate{
#'   \item Reads `API_KEY` from `Sys.getenv()`. This is the only required secret.
#'   \item Looks up the model using `resolve_model_info()` to get its
#'         `engine` and `provider`.
#'   \item Builds the correct Azure endpoint URL:
#'         \itemize{
#'           \item If `provider == "openai"`:
#'             \code{ASKR_OPENAI_BASE/openai/deployments/{engine}/chat/completions?api-version=ASKR_OPENAI_VER}
#'           \item Otherwise:
#'             \code{ASKR_OSS_BASE/models/chat/completions?api-version=ASKR_OSS_VER}
#'         }
#'   \item Sends a unified request body (always includes `model` and `messages`).
#'   \item Returns a structured object of class `"askr_response"`.
#' }
#'
#' **PII notice:** The `query` argument is transmitted to an external Azure
#' endpoint. Do not include raw personally identifiable information (names,
#' participant IDs, verbatim free-text survey responses, etc.) unless your
#' data governance policy explicitly permits it. Pre-process or anonymise
#' sensitive text before passing it as a prompt.
#'
#' @param query Character scalar. Prompt / instruction text. Must be 32,000
#'   characters or fewer (approximately 8,000 tokens).
#' @param model Character scalar. Alias or engine from the registry.
#' @param temperature Numeric scalar. Sampling temperature. Default 0.7.
#' @param system_prompt Character scalar. System-level instruction sent before
#'   the user query. Default \code{"You are a helpful AI assistant."}. Override
#'   to set domain-specific context (e.g. \code{"You are an expert in leadership
#'   development."}).
#' @param extra_params Named list of additional body parameters to merge into
#'   the request (e.g. \code{list(max_tokens = 512, top_p = 0.9)}). Values here
#'   override any defaults. Unknown parameters are passed through as-is.
#'
#' @return
#' A list of class `"askr_response"` with elements:
#' \describe{
#'   \item{ok}{Logical. TRUE on success (HTTP 200).}
#'   \item{status}{Integer HTTP status code, or `NA` if request didn't send.}
#'   \item{model}{Character. The resolved deployment/engine used.}
#'   \item{response}{Character. Model output text, or an error message.}
#' }
#'
#' @examples
#' \dontrun{
#' Sys.setenv(API_KEY = "your-azure-token")
#' res <- ask_raw(
#'   query = "Summarize this transcript in 3 leadership insights.",
#'   model = "mistral",
#'   temperature = 0.4
#' )
#' print(res)
#' }
#'
#' @importFrom httr2 request req_headers req_body_json req_perform
#' @importFrom httr2 req_error resp_status resp_body_string resp_body_json
#' @export
ask_raw <- function(query, model, temperature = 0.7,
                    system_prompt = "You are a helpful AI assistant.",
                    extra_params  = list()) {
  if (missing(query) || length(query) != 1L || is.na(query) || !nzchar(query)) {
    stop("ask_raw(): `query` must be a non-empty string.", call. = FALSE)
  }
  if (missing(model) || length(model) != 1L || is.na(model) || !nzchar(model)) {
    stop("ask_raw(): `model` must be a non-empty string.", call. = FALSE)
  }
  if (!is.numeric(temperature) || length(temperature) != 1L) {
    stop("ask_raw(): `temperature` must be a single numeric value.", call. = FALSE)
  }
  if (!is.character(system_prompt) || length(system_prompt) != 1L || is.na(system_prompt)) {
    stop("ask_raw(): `system_prompt` must be a single character string.", call. = FALSE)
  }
  if (!is.list(extra_params)) {
    stop("ask_raw(): `extra_params` must be a named list.", call. = FALSE)
  }
  if (nchar(query) > 32000L) {
    stop(
      "ask_raw(): `query` exceeds 32,000 characters. ",
      "Truncate or summarise the input before sending.",
      call. = FALSE
    )
  }

  api_key <- Sys.getenv("API_KEY", unset = "")
  if (api_key == "") {
    stop(
      "ask_raw(): Missing API_KEY. ",
      "Set it with Sys.setenv(API_KEY = 'your-azure-token').",
      call. = FALSE
    )
  }

  if (ASKR_OPENAI_BASE == "") {
    stop(
      "ask_raw(): Missing ASKR_OPENAI_BASE. ",
      "Add it to ~/.Renviron or call Sys.setenv(ASKR_OPENAI_BASE = 'https://your-resource.cognitiveservices.azure.com').",
      call. = FALSE
    )
  }
  if (ASKR_OSS_BASE == "") {
    stop(
      "ask_raw(): Missing ASKR_OSS_BASE. ",
      "Add it to ~/.Renviron or call Sys.setenv(ASKR_OSS_BASE = 'https://your-resource.services.ai.azure.com').",
      call. = FALSE
    )
  }

  info     <- resolve_model_info(model)
  engine   <- info$engine
  provider <- tolower(info$provider)

  # URL construction (provider decides which base/version pair to use)
  url <- if (provider == "openai") {
    sprintf(
      "%s/openai/deployments/%s/chat/completions?api-version=%s",
      ASKR_OPENAI_BASE,
      engine,
      ASKR_OPENAI_VER
    )
  } else {
    sprintf(
      "%s/models/chat/completions?api-version=%s",
      ASKR_OSS_BASE,
      ASKR_OSS_VER
    )
  }

  body_list <- list(
    model = engine,
    messages = list(
      list(role = "system", content = system_prompt),
      list(role = "user",   content = query)
    ),
    temperature = temperature
  )
  # Merge extra_params — caller values win; duplicates from defaults are dropped
  if (length(extra_params) > 0L) {
    body_list[names(extra_params)] <- extra_params
  }

  # req_error(is_error = ~FALSE) tells httr2 not to signal HTTP errors as
  # conditions — we inspect the status code ourselves so we can truncate
  # error bodies and avoid losing the response object.
  res <- tryCatch(
    httr2::request(url) |>
      httr2::req_headers(
        Authorization  = paste("Bearer", api_key),
        `Content-Type` = "application/json"
      ) |>
      httr2::req_body_json(body_list) |>
      httr2::req_error(is_error = \(r) FALSE) |>
      httr2::req_perform(),
    error = function(e) e  # network / DNS / timeout only
  )

  # Network-level failure (DNS, timeout, connection refused, etc.)
  if (inherits(res, "error")) {
    return(structure(list(
      ok       = FALSE,
      status   = NA_integer_,
      model    = engine,
      response = paste("Request error:", conditionMessage(res))
    ), class = "askr_response"))
  }

  http_status <- httr2::resp_status(res)

  if (http_status != 200L) {
    err_txt <- tryCatch(
      httr2::resp_body_string(res),
      error = function(e) paste("(could not read error body:", e$message, ")")
    )
    # Truncate error bodies — Azure error responses can echo back request
    # content, which may contain sensitive data passed in the prompt.
    if (nchar(err_txt) > 500L) {
      err_txt <- paste0(substr(err_txt, 1L, 500L), " ... [truncated]")
    }
    return(structure(list(
      ok       = FALSE,
      status   = http_status,
      model    = engine,
      response = err_txt
    ), class = "askr_response"))
  }

  payload <- tryCatch(
    httr2::resp_body_json(res),
    error = function(e) {
      structure(list(
        ok       = FALSE,
        status   = http_status,
        model    = engine,
        response = paste0(
          "ask_raw(): Could not parse JSON response. ",
          "Parser error: ", e$message
        )
      ), class = "askr_response")
    }
  )

  if (inherits(payload, "askr_response")) return(payload)

  msg <- tryCatch(
    payload$choices[[1]]$message$content,
    error = function(e) {
      structure(list(
        ok       = FALSE,
        status   = http_status,
        model    = engine,
        response = paste0(
          "ask_raw(): Could not extract model response from API payload. ",
          "Parser error: ", e$message
        )
      ), class = "askr_response")
    }
  )

  if (inherits(msg, "askr_response")) return(msg)

  if (is.null(msg)) {
    return(structure(list(
      ok       = FALSE,
      status   = http_status,
      model    = engine,
      response = "ask_raw(): Could not extract model response from API payload."
    ), class = "askr_response"))
  }

  structure(list(
    ok       = TRUE,
    status   = http_status,
    model    = engine,
    response = msg
  ), class = "askr_response")
}
