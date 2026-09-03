# Design Decisions

This file captures key design choices and their tradeoffs.

## 1. Two-level API (`ask` + `ask_raw`)

Decision:

- Provide a simple high-level function and a structured low-level function.

Why:

- New users need minimal complexity.
- Developers need status codes and metadata.

Tradeoff:

- Slight duplication of interface concepts.

## 2. Registry-driven model configuration

Decision:

- Models are configured in JSON (`inst/config/models.json`) instead of hardcoded throughout function logic.

Why:

- Easy to add/disable models without rewriting core request code.
- Better separation between configuration and behavior.

Tradeoff:

- Requires strict schema validation.

## 3. Provider-based endpoint routing

Decision:

- Route based on `provider` value (`openai` vs non-openai).

Why:

- Supports Azure OpenAI and Azure OSS-style deployments behind one API.

Tradeoff:

- Non-openai providers share one route path and may need future specialization.

## 4. Environment variable for auth

Decision:

- Read `API_KEY` only from environment.

Why:

- Keeps secrets out of source code and model registry files.

Tradeoff:

- Users must set runtime environment correctly.

## 5. Structured failures over silent fallback

Decision:

- Return explicit status and payload on API errors.

Why:

- Improves debugging and observability in scripts.

Tradeoff:

- Users must handle non-200 responses explicitly in robust workflows.

## 6. Internal constants for endpoints and API versions

Decision:

- Keep endpoint URLs and API versions centralized in `R/constants.R`.

Why:

- Infrastructure changes become one-file updates.

Tradeoff:

- Requires release cycle for updates instead of runtime overrides.
