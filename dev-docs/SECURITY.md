# Security Guide

This document covers secure usage practices for `askr`.

## Secrets Handling

- Use `API_KEY` environment variable only.
- Never hardcode tokens in source files.
- Never commit `.Renviron` or token-containing scripts.
- Avoid printing `Sys.getenv("API_KEY")` in logs.

## Data Handling

- Assume prompts and responses may contain sensitive business data.
- Minimize personal or confidential data sent to models.
- Apply organizational policies for data classification and retention.

## Access Control

- Use least-privilege API tokens.
- Rotate tokens on a regular schedule.
- Revoke tokens immediately if compromise is suspected.

## Package-Level Hardening Opportunities

Future improvements you may add:

- Built-in request retries with capped exponential backoff.
- Optional request timeout configuration.
- Optional redaction helper for prompt logging.
- Optional `validate = TRUE` mode for stricter payload checks.

## Incident Response Basics

If key leakage is suspected:

1. Revoke the exposed API key.
2. Issue a replacement key.
3. Update all environments using `API_KEY`.
4. Review logs for unusual usage patterns.
