make_reg <- function(rows) {
  data.frame(
    alias    = sapply(rows, `[[`, "alias"),
    engine   = sapply(rows, `[[`, "engine"),
    provider = sapply(rows, `[[`, "provider"),
    enabled  = sapply(rows, `[[`, "enabled"),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------

test_that("list_available_models() returns enabled aliases", {
  reg <- make_reg(list(
    list(alias = "gpt-4o",  engine = "gpt-4o",             provider = "openai",  enabled = TRUE),
    list(alias = "mistral", engine = "mistral-medium-2505", provider = "mistral", enabled = TRUE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  result <- list_available_models()
  expect_type(result, "character")
  expect_setequal(result, c("gpt-4o", "mistral"))
})

test_that("list_available_models() excludes disabled models", {
  reg <- make_reg(list(
    list(alias = "active",   engine = "active-engine",   provider = "openai", enabled = TRUE),
    list(alias = "inactive", engine = "inactive-engine", provider = "openai", enabled = FALSE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  result <- list_available_models()
  expect_equal(result, "active")
})

test_that("list_available_models() returns character(0) when all models disabled", {
  reg <- make_reg(list(
    list(alias = "m", engine = "e", provider = "p", enabled = FALSE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  result <- suppressMessages(list_available_models())
  expect_equal(result, character(0))
})

test_that("list_available_models() returns character(0) on empty registry", {
  reg <- data.frame(
    alias = character(0), engine = character(0),
    provider = character(0), enabled = logical(0),
    stringsAsFactors = FALSE
  )
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  result <- suppressMessages(list_available_models())
  expect_equal(result, character(0))
})

test_that("list_available_models() falls back to engine when alias is empty string", {
  reg <- make_reg(list(
    list(alias = "", engine = "mistral-medium-2505", provider = "mistral", enabled = TRUE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  result <- list_available_models()
  expect_equal(result, "mistral-medium-2505")
})

test_that("list_available_models() works against the real installed registry", {
  result <- list_available_models()
  expect_type(result, "character")
  expect_gt(length(result), 0L)
})
