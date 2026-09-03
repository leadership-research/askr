# API Reference

This reference describes the exported package API.

## `ask(prompt, model, temperature = 0.7)`

Purpose: beginner-friendly helper returning plain text.

Inputs:

- `prompt`: non-empty string.
- `model`: model alias or engine string.
- `temperature`: single numeric value.

Behavior:

- Calls `ask_raw(query = prompt, ...)`.
- On success returns model text.
- On failure returns a formatted error string starting with `[ask() error]`.

When to use:

- Interactive work.
- Scripts where a plain text output is enough.

## `ask_raw(query, model, temperature = 0.7)`

Purpose: low-level call returning status and metadata.

Inputs:

- `query`: non-empty string.
- `model`: alias or engine.
- `temperature`: single numeric value.

Behavior:

- Reads `API_KEY` from environment.
- Resolves model via `resolve_model_info()`.
- Routes request by provider:
  - `provider == "openai"` -> Azure OpenAI deployments endpoint.
  - otherwise -> Azure OSS chat endpoint.
- Sends unified chat payload with system and user messages.

Returns:

`askr_response` list with:

- `ok` (`TRUE`/`FALSE`)
- `status` (HTTP code or `NA`)
- `model` (resolved engine)
- `response` (model output or error message)

## `list_available_models()`

Purpose: list all enabled aliases from the model registry.

Returns:

- character vector of enabled aliases.
- `character(0)` if none are enabled.

## `load_model_registry()`

Purpose: load `inst/config/models.json` (from installed package path).

Validates required columns:

- `alias`
- `engine`
- `provider`
- `enabled`

Normalizes:

- `provider` to lowercase.
- `enabled` to logical when possible.

## `resolve_model_info(model_name)`

Purpose: resolve alias/engine into request metadata.

Returns list:

- `engine`
- `provider`

Constraints:

- only models with `enabled == TRUE` can resolve.

## `resolve_model(model_name)`

Purpose: backward-compatible helper.

Returns:

- resolved `engine` string only.

## `print.askr_response(x, ...)`

Purpose: S3 print method for `ask_raw()` results.

Output includes:

- `ok`
- `status`
- `model`
- `text`

## Internal Constants

Defined in `R/constants.R`:

- `ASKR_OPENAI_BASE`
- `ASKR_OSS_BASE`
- `ASKR_OPENAI_VER`
- `ASKR_OSS_VER`

These control API endpoints and versions.
