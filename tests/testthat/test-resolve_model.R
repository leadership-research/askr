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
# resolve_model_info() — input validation
# ---------------------------------------------------------------------------

test_that("resolve_model_info() errors on missing model_name", {
  expect_error(resolve_model_info(), "model_name")
})

test_that("resolve_model_info() errors on empty string", {
  expect_error(resolve_model_info(""), "model_name")
})

test_that("resolve_model_info() errors on NA", {
  expect_error(resolve_model_info(NA_character_), "model_name")
})

test_that("resolve_model_info() errors on length > 1", {
  expect_error(resolve_model_info(c("gpt-4o", "mistral")), "model_name")
})

# ---------------------------------------------------------------------------
# resolve_model_info() — alias matching
# ---------------------------------------------------------------------------

test_that("resolve_model_info() resolves by alias (exact match)", {
  reg <- make_reg(list(
    list(alias = "gpt-4o", engine = "gpt-4o-engine", provider = "openai", enabled = TRUE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  result <- resolve_model_info("gpt-4o")
  expect_equal(result$engine,   "gpt-4o-engine")
  expect_equal(result$provider, "openai")
})

test_that("resolve_model_info() alias match is case-insensitive", {
  reg <- make_reg(list(
    list(alias = "GPT-4O", engine = "gpt-4o-engine", provider = "openai", enabled = TRUE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  result <- resolve_model_info("gpt-4o")
  expect_equal(result$engine, "gpt-4o-engine")
})

# ---------------------------------------------------------------------------
# resolve_model_info() — engine fallback
# ---------------------------------------------------------------------------

test_that("resolve_model_info() falls back to engine match when alias misses", {
  reg <- make_reg(list(
    list(alias = "mistral", engine = "mistral-medium-2505", provider = "mistral", enabled = TRUE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  result <- resolve_model_info("mistral-medium-2505")
  expect_equal(result$engine, "mistral-medium-2505")
})

# ---------------------------------------------------------------------------
# resolve_model_info() — disabled models
# ---------------------------------------------------------------------------

test_that("resolve_model_info() ignores disabled models", {
  reg <- make_reg(list(
    list(alias = "old-model", engine = "old-engine", provider = "openai", enabled = FALSE),
    list(alias = "active",    engine = "active-engine", provider = "openai", enabled = TRUE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  # disabled model is invisible — should error as not found, not as "no enabled models"
  expect_error(resolve_model_info("old-model"), "not found")
})

test_that("resolve_model_info() errors when all models are disabled", {
  reg <- make_reg(list(
    list(alias = "m", engine = "e", provider = "p", enabled = FALSE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  expect_error(resolve_model_info("m"), "No models are enabled")
})

# ---------------------------------------------------------------------------
# resolve_model_info() — not found
# ---------------------------------------------------------------------------

test_that("resolve_model_info() errors with informative message on unknown model", {
  reg <- make_reg(list(
    list(alias = "gpt-4o", engine = "gpt-4o", provider = "openai", enabled = TRUE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  err <- expect_error(resolve_model_info("does-not-exist"))
  expect_match(conditionMessage(err), "not found")
  expect_match(conditionMessage(err), "gpt-4o")
})

# ---------------------------------------------------------------------------
# resolve_model() — backward-compat shim
# ---------------------------------------------------------------------------

test_that("resolve_model() returns only the engine string", {
  reg <- make_reg(list(
    list(alias = "phi4", engine = "Phi-4", provider = "microsoft", enabled = TRUE)
  ))
  local_mocked_bindings(load_model_registry = function() reg, .package = "askr")
  result <- resolve_model("phi4")
  expect_type(result, "character")
  expect_equal(result, "Phi-4")
})
