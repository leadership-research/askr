make_registry <- function(rows) {
  data.frame(
    alias    = sapply(rows, `[[`, "alias"),
    engine   = sapply(rows, `[[`, "engine"),
    provider = sapply(rows, `[[`, "provider"),
    enabled  = sapply(rows, `[[`, "enabled"),
    stringsAsFactors = FALSE
  )
}

minimal_registry <- make_registry(list(
  list(alias = "gpt-4o",  engine = "gpt-4o",             provider = "openai",  enabled = TRUE),
  list(alias = "mistral", engine = "mistral-medium-2505", provider = "mistral", enabled = TRUE)
))

# Build a minimal fake httr2 response using httr2's own constructor.
fake_resp <- function(status, body_list) {
  httr2::response(
    status  = as.integer(status),
    headers = list(`content-type` = "application/json; charset=utf-8"),
    body    = charToRaw(jsonlite::toJSON(body_list, auto_unbox = TRUE))
  )
}

# Convenience: run code with registry + base URL constants mocked.
with_mocks <- function(mock_perform, code) {
  local_mocked_bindings(
    ASKR_OPENAI_BASE    = "https://fake-openai.com",
    ASKR_OSS_BASE       = "https://fake-oss.com",
    load_model_registry = function() minimal_registry,
    .package = "askr"
  )
  httr2::with_mocked_responses(mock_perform, code)
}

# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------

test_that("ask_raw() errors on missing query", {
  expect_error(ask_raw(model = "gpt-4o"), "query")
})

test_that("ask_raw() errors on empty query", {
  expect_error(ask_raw(query = "", model = "gpt-4o"), "query")
})

test_that("ask_raw() errors on NA query", {
  expect_error(ask_raw(query = NA_character_, model = "gpt-4o"), "query")
})

test_that("ask_raw() errors on missing model", {
  expect_error(ask_raw(query = "hello"), "model")
})

test_that("ask_raw() errors on empty model", {
  expect_error(ask_raw(query = "hello", model = ""), "model")
})

test_that("ask_raw() errors on non-character system_prompt", {
  expect_error(
    ask_raw(query = "hello", model = "gpt-4o", system_prompt = 42),
    "system_prompt"
  )
})

test_that("ask_raw() errors on NA system_prompt", {
  expect_error(
    ask_raw(query = "hello", model = "gpt-4o", system_prompt = NA_character_),
    "system_prompt"
  )
})

test_that("ask_raw() errors when extra_params is not a list", {
  expect_error(
    ask_raw(query = "hello", model = "gpt-4o", extra_params = "bad"),
    "extra_params"
  )
})

test_that("ask_raw() errors on non-numeric temperature", {
  expect_error(
    ask_raw(query = "hello", model = "gpt-4o", temperature = "hot"),
    "temperature"
  )
})

test_that("ask_raw() errors on vector temperature", {
  expect_error(
    ask_raw(query = "hello", model = "gpt-4o", temperature = c(0.5, 0.7)),
    "temperature"
  )
})

test_that("ask_raw() errors when query exceeds 32,000 characters", {
  long_query <- paste(rep("a", 32001L), collapse = "")
  expect_error(ask_raw(query = long_query, model = "gpt-4o"), "32,000")
})

test_that("ask_raw() accepts query at exactly 32,000 characters", {
  boundary_query <- paste(rep("a", 32000L), collapse = "")
  # Should not error on the length guard — any subsequent failure (auth,
  # network, etc.) is fine; we only care it gets past the 32k check.
  err <- tryCatch(
    ask_raw(query = boundary_query, model = "gpt-4o"),
    error = function(e) e
  )
  # If ask_raw() returned an askr_response (CI env vars set, HTTP failed),
  # the length guard was not triggered — that's the correct outcome.
  if (inherits(err, "askr_response")) {
    expect_false(err$ok)  # HTTP failed as expected in CI without real creds
  } else {
    expect_false(grepl("32,000", conditionMessage(err)))
  }
})

# ---------------------------------------------------------------------------
# Auth guard
# ---------------------------------------------------------------------------

test_that("ask_raw() errors with actionable message when API_KEY is missing", {
  withr::with_envvar(c(API_KEY = ""), {
    err <- expect_error(ask_raw(query = "hi", model = "gpt-4o"))
    expect_match(conditionMessage(err), "API_KEY")
  })
})

# ---------------------------------------------------------------------------
# Endpoint guards
# ---------------------------------------------------------------------------

test_that("ask_raw() errors with actionable message when ASKR_OPENAI_BASE is unset", {
  local_mocked_bindings(
    ASKR_OPENAI_BASE = "",
    ASKR_OSS_BASE    = "https://fake.oss.com",
    .package = "askr"
  )
  withr::with_envvar(c(API_KEY = "fake-key"), {
    expect_error(ask_raw(query = "hi", model = "gpt-4o"), "ASKR_OPENAI_BASE")
  })
})

test_that("ask_raw() errors with actionable message when ASKR_OSS_BASE is unset", {
  local_mocked_bindings(
    ASKR_OPENAI_BASE = "https://fake.openai.com",
    ASKR_OSS_BASE    = "",
    .package = "askr"
  )
  withr::with_envvar(c(API_KEY = "fake-key"), {
    expect_error(ask_raw(query = "hi", model = "gpt-4o"), "ASKR_OSS_BASE")
  })
})

# ---------------------------------------------------------------------------
# HTTP success path
# ---------------------------------------------------------------------------

test_that("ask_raw() returns askr_response with ok=TRUE on HTTP 200", {
  resp_body <- list(
    choices = list(list(message = list(role = "assistant", content = "Hello!")))
  )
  withr::with_envvar(c(API_KEY = "fake-key"), {
    with_mocks(
      function(req) fake_resp(200L, resp_body),
      {
        result <- ask_raw(query = "Say hello", model = "gpt-4o")
        expect_s3_class(result, "askr_response")
        expect_true(result$ok)
        expect_equal(result$status, 200L)
        expect_equal(result$response, "Hello!")
        expect_equal(result$model, "gpt-4o")
      }
    )
  })
})

# ---------------------------------------------------------------------------
# system_prompt and extra_params
# ---------------------------------------------------------------------------

test_that("ask_raw() sends custom system_prompt in request body", {
  resp_body    <- list(choices = list(list(message = list(role = "assistant", content = "ok"))))
  captured_body <- NULL
  withr::with_envvar(c(API_KEY = "fake-key"), {
    with_mocks(
      function(req) {
        captured_body <<- req$body$data  # httr2 req_body_json stores as list
        fake_resp(200L, resp_body)
      },
      {
        ask_raw(
          query         = "hi",
          model         = "gpt-4o",
          system_prompt = "You are a leadership coach."
        )
      }
    )
  })
  system_msg <- captured_body$messages[[1]]
  expect_equal(system_msg$role,    "system")
  expect_equal(system_msg$content, "You are a leadership coach.")
})

test_that("ask_raw() uses default system_prompt when not specified", {
  resp_body    <- list(choices = list(list(message = list(role = "assistant", content = "ok"))))
  captured_body <- NULL
  withr::with_envvar(c(API_KEY = "fake-key"), {
    with_mocks(
      function(req) {
        captured_body <<- req$body$data
        fake_resp(200L, resp_body)
      },
      { ask_raw(query = "hi", model = "gpt-4o") }
    )
  })
  system_msg <- captured_body$messages[[1]]
  expect_equal(system_msg$content, "You are a helpful AI assistant.")
})

test_that("ask_raw() merges extra_params into request body", {
  resp_body    <- list(choices = list(list(message = list(role = "assistant", content = "ok"))))
  captured_body <- NULL
  withr::with_envvar(c(API_KEY = "fake-key"), {
    with_mocks(
      function(req) {
        captured_body <<- req$body$data
        fake_resp(200L, resp_body)
      },
      {
        ask_raw(
          query        = "hi",
          model        = "gpt-4o",
          extra_params = list(max_tokens = 512L, top_p = 0.9)
        )
      }
    )
  })
  expect_equal(captured_body$max_tokens, 512L)
  expect_equal(captured_body$top_p,      0.9)
})

test_that("ask_raw() extra_params override temperature when both supplied", {
  resp_body    <- list(choices = list(list(message = list(role = "assistant", content = "ok"))))
  captured_body <- NULL
  withr::with_envvar(c(API_KEY = "fake-key"), {
    with_mocks(
      function(req) {
        captured_body <<- req$body$data
        fake_resp(200L, resp_body)
      },
      {
        ask_raw(
          query        = "hi",
          model        = "gpt-4o",
          temperature  = 0.7,
          extra_params = list(temperature = 0.0)
        )
      }
    )
  })
  expect_equal(captured_body$temperature, 0.0)
})

# ---------------------------------------------------------------------------
# HTTP error paths
# ---------------------------------------------------------------------------

test_that("ask_raw() returns ok=FALSE on HTTP 401", {
  withr::with_envvar(c(API_KEY = "bad-key"), {
    with_mocks(
      function(req) fake_resp(401L, list(error = "Unauthorized")),
      {
        result <- ask_raw(query = "hi", model = "gpt-4o")
        expect_s3_class(result, "askr_response")
        expect_false(result$ok)
        expect_equal(result$status, 401L)
      }
    )
  })
})

test_that("ask_raw() truncates long error bodies on non-200 responses", {
  long_body <- list(error = paste(rep("e", 1000), collapse = ""))
  withr::with_envvar(c(API_KEY = "fake-key"), {
    with_mocks(
      function(req) fake_resp(500L, long_body),
      {
        result <- ask_raw(query = "hi", model = "gpt-4o")
        expect_false(result$ok)
        expect_lte(nchar(result$response), 520L)
        expect_match(result$response, "truncated")
      }
    )
  })
})

test_that("ask_raw() returns ok=FALSE with NA status on network error", {
  withr::with_envvar(c(API_KEY = "fake-key"), {
    with_mocks(
      function(req) httr2::response_abort("Could not resolve host"),
      {
        result <- ask_raw(query = "hi", model = "gpt-4o")
        expect_s3_class(result, "askr_response")
        expect_false(result$ok)
        expect_true(is.na(result$status))
        expect_match(result$response, "Request error")
      }
    )
  })
})

# ---------------------------------------------------------------------------
# URL routing
# ---------------------------------------------------------------------------

test_that("ask_raw() routes OSS models to ASKR_OSS_BASE", {
  resp_body    <- list(choices = list(list(message = list(role = "assistant", content = "ok"))))
  captured_url <- NULL
  withr::with_envvar(c(API_KEY = "fake-key"), {
    with_mocks(
      function(req) { captured_url <<- req$url; fake_resp(200L, resp_body) },
      { ask_raw(query = "hi", model = "mistral") }
    )
  })
  expect_match(captured_url, "fake-oss.com")
})

test_that("ask_raw() routes openai models to ASKR_OPENAI_BASE with deployments path", {
  resp_body    <- list(choices = list(list(message = list(role = "assistant", content = "ok"))))
  captured_url <- NULL
  withr::with_envvar(c(API_KEY = "fake-key"), {
    with_mocks(
      function(req) { captured_url <<- req$url; fake_resp(200L, resp_body) },
      { ask_raw(query = "hi", model = "gpt-4o") }
    )
  })
  expect_match(captured_url, "fake-openai.com")
  expect_match(captured_url, "deployments")
})

test_that("ask_raw() uses overridden ASKR_OPENAI_VER in URL", {
  resp_body    <- list(choices = list(list(message = list(role = "assistant", content = "ok"))))
  captured_url <- NULL
  local_mocked_bindings(
    ASKR_OPENAI_BASE    = "https://fake-openai.com",
    ASKR_OSS_BASE       = "https://fake-oss.com",
    ASKR_OPENAI_VER     = "2099-99-99-preview",
    load_model_registry = function() minimal_registry,
    .package = "askr"
  )
  withr::with_envvar(c(API_KEY = "fake-key"), {
    httr2::with_mocked_responses(
      function(req) { captured_url <<- req$url; fake_resp(200L, resp_body) },
      { ask_raw(query = "hi", model = "gpt-4o") }
    )
  })
  expect_match(captured_url, "2099-99-99-preview")
})

test_that("ask_raw() uses overridden ASKR_OSS_VER in URL", {
  resp_body    <- list(choices = list(list(message = list(role = "assistant", content = "ok"))))
  captured_url <- NULL
  local_mocked_bindings(
    ASKR_OPENAI_BASE    = "https://fake-openai.com",
    ASKR_OSS_BASE       = "https://fake-oss.com",
    ASKR_OSS_VER        = "2099-88-88-preview",
    load_model_registry = function() minimal_registry,
    .package = "askr"
  )
  withr::with_envvar(c(API_KEY = "fake-key"), {
    httr2::with_mocked_responses(
      function(req) { captured_url <<- req$url; fake_resp(200L, resp_body) },
      { ask_raw(query = "hi", model = "mistral") }
    )
  })
  expect_match(captured_url, "2099-88-88-preview")
})
