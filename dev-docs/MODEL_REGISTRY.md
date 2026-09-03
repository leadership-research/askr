# Model Registry Guide

`askr` uses a JSON registry to define which models can be called.

Registry location in source:

- `inst/config/models.json`

Registry location after installation:

- `system.file("config", "models.json", package = "askr")`

## Schema

Each model entry must include:

- `alias` (string): short user-facing name (example: `"gpt-4o"`).
- `engine` (string): deployment/model identifier sent to API.
- `provider` (string): route selector (`"openai"` or other provider name).
- `enabled` (boolean): whether the model is available to callers.

## Example Entry

```json
{
  "alias": "gpt-4o",
  "engine": "gpt-4o",
  "provider": "openai",
  "enabled": true
}
```

## How Resolution Works

`resolve_model_info(model_name)`:

1. Loads registry.
2. Filters to enabled rows only.
3. Matches by alias (case-insensitive).
4. If no alias hit, matches by engine (case-insensitive).
5. Returns `engine` + `provider`.

## Safe Editing Rules

- Keep aliases unique.
- Keep engines accurate to deployed model names.
- Use lowercase for provider values.
- Never commit secrets in the registry.
- Disable models by setting `enabled: false` instead of deleting when possible.

## Validation Behavior

`load_model_registry()` fails if required columns are missing.

Common failures:

- Missing column names.
- Invalid or unreadable JSON.
- Empty/invalid installed config path.

## Verification Checklist

After changing registry:

1. `list_available_models()` returns expected aliases.
2. `resolve_model_info("<alias>")` resolves expected engine/provider.
3. `ask_raw("ping", model = "<alias>")` returns `ok = TRUE` for at least one model.
