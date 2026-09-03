make_resp <- function(ok = TRUE, status = 200L, model = "gpt-4o", response = "Hello world") {
  structure(list(ok = ok, status = status, model = model, response = response),
            class = "askr_response")
}

test_that("print.askr_response() outputs key fields", {
  out <- capture.output(print(make_resp()))
  expect_true(any(grepl("askr_response", out)))
  expect_true(any(grepl("ok", out)))
  expect_true(any(grepl("200", out)))
  expect_true(any(grepl("gpt-4o", out)))
})

test_that("print.askr_response() truncates at max_chars by default", {
  long_text <- paste(rep("x", 1000), collapse = "")
  out <- capture.output(print(make_resp(response = long_text)))
  full <- paste(out, collapse = "\n")
  expect_match(full, "truncated")
  expect_false(grepl(long_text, full))
})

test_that("print.askr_response() shows full text when max_chars = Inf", {
  long_text <- paste(rep("x", 1000), collapse = "")
  out <- capture.output(print(make_resp(response = long_text), max_chars = Inf))
  full <- paste(out, collapse = "\n")
  expect_false(grepl("truncated", full))
  expect_match(full, long_text)
})

test_that("print.askr_response() does not truncate short responses", {
  out <- capture.output(print(make_resp(response = "Short.")))
  full <- paste(out, collapse = "\n")
  expect_false(grepl("truncated", full))
  expect_match(full, "Short\\.")
})

test_that("print.askr_response() handles NULL response", {
  out <- capture.output(print(make_resp(response = NULL)))
  expect_true(any(grepl("<NULL>", out)))
})

test_that("print.askr_response() returns x invisibly", {
  x <- make_resp()
  result <- withVisible(print(x))
  expect_false(result$visible)
  expect_identical(result$value, x)
})
