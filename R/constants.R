#' askr Azure endpoint constants
#'
#' These define where requests go for different provider types.
#'
#' ASKR_OPENAI_BASE:
#'   Base URL for Azure OpenAI-style deployments.
#'   Used when provider == "openai".
#'   Set via environment variable ASKR_OPENAI_BASE (e.g. in ~/.Renviron).
#'
#' ASKR_OSS_BASE:
#'   Base URL for Azure OSS-style chat models.
#'   Used for any provider that is not "openai".
#'   Set via environment variable ASKR_OSS_BASE (e.g. in ~/.Renviron).
#'
#' ASKR_OPENAI_VER and ASKR_OSS_VER:
#'   The api-version strings required by those services.
#'   Override via environment variables ASKR_OPENAI_VER and ASKR_OSS_VER
#'   when Azure deprecates the defaults.
#'
#' To configure, add to your ~/.Renviron:
#'   ASKR_OPENAI_BASE=https://your-resource.cognitiveservices.azure.com
#'   ASKR_OSS_BASE=https://your-resource.services.ai.azure.com
#'   API_KEY=your-azure-api-token
#'   ASKR_OPENAI_VER=2025-01-01-preview  # optional — override when deprecated
#'   ASKR_OSS_VER=2024-05-01-preview     # optional — override when deprecated
#'
#' Then restart R or call readRenviron("~/.Renviron").
#'
#' @keywords internal
ASKR_OPENAI_BASE <- Sys.getenv("ASKR_OPENAI_BASE", unset = "")
ASKR_OSS_BASE    <- Sys.getenv("ASKR_OSS_BASE",    unset = "")

ASKR_OPENAI_VER  <- Sys.getenv("ASKR_OPENAI_VER", unset = "2025-01-01-preview")
ASKR_OSS_VER     <- Sys.getenv("ASKR_OSS_VER",    unset = "2024-05-01-preview")
