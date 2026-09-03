# ask() is a thin wrapper over ask_raw(). Tests verify:
# - it validates prompt (distinct from ask_raw's query)
# - it returns plain text on success
# - it returns a formatted error string and never stop()s on failure

make_askr_response <- function(ok, status = 200L, model = "gpt-4o", response = "") {
  structure(
    list(ok = ok, status = status, model = model, response = response),
    class = "askr_response"
  )
}

# ---------------------------------------------------------------------------
# Input validation — fires before ask_raw() is called
# ---------------------------------------------------------------------------

test_that("ask() errors on missing prompt", {
  expect_error(ask(model = "gpt-4o"), "prompt")
})

test_that("ask() errors on empty prompt", {
  expect_error(ask(prompt = "", model = "gpt-4o"), "prompt")
})

test_that("ask() errors on NA prompt", {
  expect_error(ask(prompt = NA_character_, model = "gpt-4o"), "prompt")
})

# ---------------------------------------------------------------------------
# Input validation — new args
# ---------------------------------------------------------------------------

test_that("ask() errors on non-character system_prompt", {
  expect_error(ask(prompt = "hi", model = "gpt-4o", system_prompt = 42), "system_prompt")
})

test_that("ask() errors when extra_params is not a list", {
  expect_error(ask(prompt = "hi", model = "gpt-4o", extra_params = "bad"), "extra_params")
})

# ---------------------------------------------------------------------------
# Success path — mock ask_raw() so no credentials or network needed
# ---------------------------------------------------------------------------

test_that("ask() returns plain character text on success", {
  local_mocked_bindings(
    ask_raw = function(...) make_askr_response(ok = TRUE, response = "The answer is 42."),
    .package = "askr"
  )
  result <- ask(prompt = "What is the answer?", model = "gpt-4o")
  expect_type(result, "character")
  expect_equal(result, "The answer is 42.")
})

test_that("ask() passes system_prompt and extra_params through to ask_raw()", {
  captured_args <- NULL
  local_mocked_bindings(
    ask_raw = function(...) {
      captured_args <<- list(...)
      make_askr_response(ok = TRUE, response = "ok")
    },
    .package = "askr"
  )
  ask(
    prompt        = "hi",
    model         = "gpt-4o",
    system_prompt = "You are a coach.",
    extra_params  = list(max_tokens = 100L)
  )
  expect_equal(captured_args$system_prompt, "You are a coach.")
  expect_equal(captured_args$extra_params,  list(max_tokens = 100L))
})

# ---------------------------------------------------------------------------
# Error paths — ask() must NOT stop(), must return a formatted string
# ---------------------------------------------------------------------------

test_that("ask() returns error string (never stops) on HTTP failure", {
  local_mocked_bindings(
    ask_raw = function(...) make_askr_response(
      ok = FALSE, status = 401L, model = "gpt-4o", response = "Unauthorized"
    ),
    .package = "askr"
  )
  result <- ask(prompt = "hello", model = "gpt-4o")
  expect_type(result, "character")
  expect_match(result, "\\[ask\\(\\) error\\]")
  expect_match(result, "401")
  expect_match(result, "Unauthorized")
})

test_that("ask() error string includes the resolved model name", {
  local_mocked_bindings(
    ask_raw = function(...) make_askr_response(
      ok = FALSE, status = 500L, model = "mistral-medium-2505", response = "Server error"
    ),
    .package = "askr"
  )
  result <- ask(prompt = "hello", model = "mistral")
  expect_match(result, "mistral-medium-2505")
})

test_that("ask() returns error string on network failure (ok=FALSE, status=NA)", {
  local_mocked_bindings(
    ask_raw = function(...) make_askr_response(
      ok = FALSE, status = NA_integer_, model = "gpt-4o", response = "Request error: timeout"
    ),
    .package = "askr"
  )
  result <- ask(prompt = "hello", model = "gpt-4o")
  expect_type(result, "character")
  expect_match(result, "\\[ask\\(\\) error\\]")
})
