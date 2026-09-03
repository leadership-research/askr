# Developer Guide

This guide is for contributors extending or maintaining `askr`.

## Source Layout

- `R/ask.R`: high-level text-only wrapper.
- `R/ask_raw.R`: low-level API call and response parsing.
- `R/model_registry.R`: JSON registry loading and normalization.
- `R/resolve_model.R`: model alias/engine resolution.
- `R/list_available_models.R`: model discovery helper.
- `R/print_askr_response.R`: S3 print method.
- `R/constants.R`: endpoint and API version constants.
- `inst/config/models.json`: model registry data.
- `man/*.Rd`: generated docs from roxygen comments.

## Local Development Setup

```r
# from package root
# install.packages(c("devtools", "roxygen2", "testthat"))
devtools::load_all()
```

## Updating Documentation

1. Edit roxygen comments in `R/*.R`.
2. Regenerate docs and namespace:

```r
devtools::document()
```

3. Validate generated `man/` and `NAMESPACE` diffs.

## Testing

If/when tests are added:

```r
devtools::test()
```

For manual smoke tests today:

```r
Sys.setenv(API_KEY = "...")
list_available_models()
ask("Say hello in one sentence.", model = "gpt-4o")
```

## Adding a New Model

1. Add entry in `inst/config/models.json`.
2. Ensure `alias`, `engine`, `provider`, `enabled` are present.
3. Run `list_available_models()` and `resolve_model_info()` checks.
4. Validate one end-to-end request with `ask_raw()`.

## Release Checklist

1. Bump `Version` in `DESCRIPTION`.
2. Regenerate docs (`devtools::document()`).
3. Run tests/smoke tests.
4. Review README and docs for updated model list or behavior changes.
5. Build package:

```r
devtools::build()
```
