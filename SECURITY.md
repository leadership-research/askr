# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | Yes       |

## Reporting a Vulnerability

Do **not** open a public GitHub issue for security vulnerabilities.

Report vulnerabilities privately via [GitHub's private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability) on this repository, or email the maintainer directly.

You can expect an acknowledgement within **5 business days** and a resolution or mitigation plan within **30 days** of confirmed reproduction.

## Credential and Secret Handling

This package reads credentials exclusively from environment variables:

- `API_KEY` — Azure API token
- `ASKR_OPENAI_BASE` — Azure OpenAI endpoint URL
- `ASKR_OSS_BASE` — Azure AI Foundry endpoint URL

**Never commit credentials to source control.** Add them to `~/.Renviron` (gitignored by default in this repo) or use a secrets manager.

If you discover a committed secret in this repository's history, report it immediately so the credential can be rotated.

## Scope

The following are in scope for vulnerability reports:

- Credential leakage through error messages, logs, or API responses
- Injection via user-supplied parameters reaching shell, file paths, or eval
- Supply chain issues in declared dependencies or CI actions
- Insecure default configuration that could expose user data

The following are out of scope:

- Vulnerabilities in Azure infrastructure itself (report to Microsoft)
- Social engineering
