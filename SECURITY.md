# Security Policy

## Supported Versions

Security fixes are currently made on `main` and included in the next tagged release. The first public release line is `0.1.x`.

## Reporting A Vulnerability

Please report security issues privately by opening a GitHub Security Advisory for this repository when available, or by contacting the repository owner directly through GitHub.

Please include:

- The Markdown version or commit tested.
- macOS version and hardware architecture.
- A minimal Markdown file or folder structure that reproduces the issue.
- Whether the issue requires opening an untrusted file, clicking a link, editing, saving, or installing the app.

Avoid filing public issues for vulnerabilities until there is a fix or a coordinated disclosure plan.

## Current Security Model

Markdown is a local-first desktop app. It opens files and folders selected by the user, renders common Markdown, and writes only the selected Markdown file during editing/save flows.

The app does not support raw HTML execution, plugins, sync, backlinks, graph views, hidden indexing, or a persistent database. Link opening is explicit: `Cmd`/`Ctrl` click opens existing local Markdown files inside the app and opens external `http` / `https` URLs in the browser. Other schemes and non-Markdown local files are not opened.
