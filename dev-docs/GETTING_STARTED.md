# Getting Started with askr

This guide gets a first-time user from zero to a working AI request in R.

## 1. Prerequisites

- R 4.2.0 or newer.
- The `askr` package installed.
- A valid Azure API token set in environment variable `API_KEY`.

## 2. Install the package

From GitHub:

```r
# install.packages("devtools")
devtools::install_github("leadership-research/askr")
```

Or from a local clone:

```r
devtools::install_local(".")
```

Load package:

```r
library(askr)
```

## 3. Configure credentials

Set your API token for the current R session:

```r
Sys.setenv(API_KEY = "your-azure-token")
```

Verify it exists:

```r
nzchar(Sys.getenv("API_KEY"))
```

Expected result: `TRUE`

## 4. Run your first request

```r
response <- ask(
  prompt = "Explain regression vs classification in plain language.",
  model = "gpt-4o",
  temperature = 0.4
)

cat(response)
```

## 5. See available models

```r
list_available_models()
```

Use any returned alias in `ask()` or `ask_raw()`.

## 6. If something fails

- Read [Troubleshooting](./TROUBLESHOOTING.md).
- Confirm `API_KEY` is set.
- Confirm the model alias is enabled in the registry.
