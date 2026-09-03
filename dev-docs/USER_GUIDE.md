# User Guide

This guide focuses on day-to-day usage patterns.

## Core Functions

- `ask()`: high-level helper; returns text.
- `ask_raw()`: low-level helper; returns structured response metadata.

## Pattern 1: Quick analysis in one line

```r
ask("Summarize this meeting transcript in 5 bullets.", model = "mistral")
```

Use this when you only need generated text.

## Pattern 2: Programmatic handling with status checks

```r
res <- ask_raw(
  query = "Extract 3 key risks from the report.",
  model = "gpt-4o",
  temperature = 0.3
)

if (res$ok) {
  cat(res$response)
} else {
  message("Request failed: ", res$status)
  message(res$response)
}
```

Use this for scripts, pipelines, and robust error handling.

## Pattern 3: Stable scripts with model aliases

Prefer aliases (`"gpt-4o"`, `"mistral"`) over hardcoding engine strings.

Reason: engine names may change over time while alias remains stable in your registry.

## Pattern 4: Reproducible prompt usage

Create prompt variables and version them in scripts:

```r
prompt_v1 <- "Summarize the transcript and return 3 leadership themes."
res <- ask_raw(prompt_v1, model = "gpt-5", temperature = 0.2)
```

## Pattern 5: Interactive vs production usage

- Interactive notebooks: use `ask()` for speed and readability.
- Scheduled jobs/pipelines: use `ask_raw()` and inspect `ok/status`.

## Response Object (`ask_raw`)

`ask_raw()` returns `askr_response` with fields:

- `ok`: TRUE/FALSE
- `status`: HTTP code or `NA`
- `model`: resolved engine used in the request
- `response`: model text or error payload

## Good Defaults

- `temperature = 0.2` to `0.5` for analysis and extraction.
- `temperature = 0.7` (package default) for more open-ended generation.

## Safe Usage Tips

- Do not log or print `API_KEY`.
- Treat generated text as draft output; review before final publication.
- For high-stakes decisions, keep a human review step.
