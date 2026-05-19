# Contributing

This repository is maintained by Databricks and intended for contributions from Databricks Field Engineers. While the repository is public and meant to help anyone developing projects that use Databricks, external contributions are not currently accepted. Feel free to open an issue with requests or suggestions.


## Project layout

```
.
├── PowerBI-migration-accelerator.ps1    # thin CLI wrapper
├── Configuration.json                   # default configuration
├── Configuration.schema.json            # JSON Schema used for validation
├── src/                                 # PowerShell module
│   ├── PBIMigrationAccelerator.psd1     # manifest
│   ├── PBIMigrationAccelerator.psm1     # module loader
│   ├── Public/                          # exported cmdlets
│   ├── Private/                         # internal helpers
│   └── Callbacks/                       # regex MatchEvaluator modules
├── tests/                               # Pester 5 tests
├── scripts/                             # demo and developer helpers
├── configurations/                      # platform-specific example configs
├── samples-pbip/…                       # sample Power BI projects
└── docs/                                # extended documentation
```

## Prerequisites

- PowerShell 7.4+ (Core)
- Pester 5.x
- PSScriptAnalyzer 1.22+

Install the tooling once:

```powershell
Install-Module -Name Pester -RequiredVersion 5.5.0 -Scope CurrentUser -Force -SkipPublisherCheck
Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.22.0 -Scope CurrentUser -Force
```

## Local checks

Run both checks before opening a pull request; CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs the same commands.

```powershell
# Lint
Invoke-ScriptAnalyzer -Path . -Settings ./PSScriptAnalyzerSettings.psd1 -Recurse

# Tests
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

## Coding conventions

- All public functions are Verb-Noun (use `Get-Verb` to pick an approved verb) and carry comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and at least one `.EXAMPLE`.
- Every function uses `[CmdletBinding()]`; state-changing functions use `[CmdletBinding(SupportsShouldProcess)]` and honor `-WhatIf`.
- Use typed and validated parameters (`[ValidateNotNullOrEmpty()]`, `[ValidateScript({ ... })]`).
- Prefer `Write-Information`, `Write-Verbose`, `Write-Warning` over `Write-Host`. Use the internal `Write-MigrationLog` for colored user-facing output.
- 4-space indentation, one statement per line. PSScriptAnalyzer rules are the source of truth; keep its output clean.
- Never introduce global state. Pass stats through the `Stats` parameter (see `New-MigrationStats`).
- New callback modules live under `src/Callbacks/`, export their public function with `Export-ModuleMember`, and ship with Pester coverage under `tests/Callbacks/`.

## Regex update rules

When you add or change a regex rule in a `*.json` config:

1. Make sure the JSON still validates against [Configuration.schema.json](./Configuration.schema.json).
2. Add a Pester case under `tests/Private/Update-MExpression.Tests.ps1` (or a new file) that demonstrates the before/after.
3. If you change a shipped platform config, update or add a `tests/Fixtures/MExpressions/<Source>.{before,after}.m` pair so the end-to-end test in [Update-MExpression.Sources.Tests.ps1](./tests/Private/Update-MExpression.Sources.Tests.ps1) continues to pass.

## Testing scope

- Unit-test everything under `Private/` and `Callbacks/`. Those modules are pure functions and trivially testable with Pester.
- The public entry points (`Invoke-PBIMigration`, `Update-PBIDatabase`) take a live TOM `Database` instance and need a Power BI Service connection, so they are covered by the regex/fixture tests above plus manual smoke runs against the `samples-pbip/` folder. There is intentionally no `tests/Public/` directory; integration tests that require a live service belong in a separate manual validation pass.

## Pull requests

- Reference the customer UCO or use case in the PR description when possible.
- Keep the diff focused. Mechanical reorgs and logic changes should land in separate commits.
- Update [CHANGELOG.md](./CHANGELOG.md) under `## [Unreleased]` for any behavior change.
- Make sure PSScriptAnalyzer and Pester are green locally before requesting review.
