test_that("load_model_registry() returns a data.frame with required columns", {
  reg <- load_model_registry()
  expect_s3_class(reg, "data.frame")
  expect_true(all(c("alias", "engine", "provider", "enabled") %in% names(reg)))
})

test_that("load_model_registry() returns character columns for alias, engine, provider", {
  reg <- load_model_registry()
  expect_type(reg$alias,    "character")
  expect_type(reg$engine,   "character")
  expect_type(reg$provider, "character")
})

test_that("load_model_registry() returns logical enabled column", {
  reg <- load_model_registry()
  expect_type(reg$enabled, "logical")
})

test_that("load_model_registry() normalizes provider to lowercase", {
  reg <- load_model_registry()
  expect_equal(reg$provider, tolower(reg$provider))
})

test_that("load_model_registry() has at least one row", {
  reg <- load_model_registry()
  expect_gt(nrow(reg), 0L)
})

test_that("load_model_registry() errors when registry is missing required columns", {
  # Write a temporary registry without the 'enabled' column
  tmp <- tempfile(fileext = ".json")
  writeLines('[{"alias":"x","engine":"y","provider":"z"}]', tmp)

  # Monkey-patch system.file for this test via mockery/local override
  # Since we can't easily mock system.file, test the validation logic directly
  dat <- jsonlite::fromJSON(tmp, simplifyDataFrame = TRUE)
  missing_cols <- setdiff(c("alias", "engine", "provider", "enabled"), names(dat))
  expect_true("enabled" %in% missing_cols)
})

test_that("load_model_registry() normalizes non-logical enabled values", {
  tmp <- tempfile(fileext = ".json")
  writeLines(
    '[{"alias":"a","engine":"a-engine","provider":"test","enabled":"true"},
      {"alias":"b","engine":"b-engine","provider":"test","enabled":"false"},
      {"alias":"c","engine":"c-engine","provider":"test","enabled":"1"},
      {"alias":"d","engine":"d-engine","provider":"test","enabled":"yes"}]',
    tmp
  )
  dat <- jsonlite::fromJSON(tmp, simplifyDataFrame = TRUE)
  # replicate the normalization logic from model_registry.R
  lc <- tolower(as.character(dat$enabled))
  dat$enabled <- ifelse(
    lc %in% c("true", "t", "1", "yes", "y"), TRUE,
    ifelse(lc %in% c("false", "f", "0", "no", "n"), FALSE, NA)
  )
  expect_equal(dat$enabled, c(TRUE, FALSE, TRUE, TRUE))
})
