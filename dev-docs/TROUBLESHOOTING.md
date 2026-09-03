# Troubleshooting

## Error: Missing API key

Symptom:

- `ask_raw(): Missing API_KEY...`

Fix:

```r
Sys.setenv(API_KEY = "your-azure-token")
```

## Error: Model not found among enabled models

Symptom:

- `Model '<name>' not found among enabled models.`

Fix:

1. Check valid aliases:

```r
list_available_models()
```

2. Update `inst/config/models.json` if needed.
3. Confirm target model has `"enabled": true`.

## Error: HTTP non-200 response

Symptom:

- `ask_raw()` returns `ok = FALSE` with `status != 200`.

Fix:

- Verify API key scope/permission.
- Verify endpoint/version constants in `R/constants.R`.
- Verify engine name exists and is deployed.
- Inspect `res$response` payload for service-specific details.

## Error: Network/request failures (`status = NA`)

Symptom:

- `Request error: ...` in response.

Fix:

- Check network connectivity and firewall access.
- Retry request.
- If running in restricted environments, confirm access to Azure endpoints.

## Registry file problems

Symptom:

- `could not locate config/models.json`
- missing required columns

Fix:

- Ensure `inst/config/models.json` exists before package installation.
- Reinstall package after modifying files.
- Validate JSON syntax.

## Unexpected or empty model text

Symptom:

- Response parsing cannot extract assistant content.

Fix:

- Capture and inspect full payload from service.
- Confirm API response format still has `choices[[1]]$message$content`.
- Update parsing logic in `R/ask_raw.R` if upstream schema changed.
