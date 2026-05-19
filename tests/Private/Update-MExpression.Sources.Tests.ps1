#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $RepoRoot   = Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '../..')
    $ModuleRoot = Join-Path -Path $RepoRoot -ChildPath 'src'
    . (Join-Path -Path $ModuleRoot -ChildPath 'Private/Write-MigrationLog.ps1')
    . (Join-Path -Path $ModuleRoot -ChildPath 'Private/Update-MExpression.ps1')

    function Read-FixtureText {
        param([string]$Path)
        (Get-Content -LiteralPath $Path -Raw) -replace "`r`n", "`n"
    }

    function Get-EnabledRules {
        param([string]$ConfigPath)
        $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        @($config.Updates | Where-Object { $_.Enabled -eq $true } | Sort-Object Order)
    }
}

Describe 'Update-MExpression with shipped source rules' -Tag 'Integration' {
    It 'applies the Databricks rules end-to-end' {
        $beforePath = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Databricks.before.m'
        $afterPath  = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Databricks.after.m'
        $configPath = Join-Path $RepoRoot 'configurations/Databricks.json'

        $rules = Get-EnabledRules -ConfigPath $configPath
        $rules.Count | Should -BeGreaterThan 0

        $before   = Read-FixtureText -Path $beforePath
        $expected = Read-FixtureText -Path $afterPath
        $actual   = Update-MExpression -Expression $before -UpdateRules $rules -ModuleRoot $RepoRoot
        $actual   = $actual -replace "`r`n", "`n"

        $actual | Should -Be $expected
    }

    It 'applies the Databricks-Incremental-Refresh rules end-to-end' {
        $beforePath = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Databricks-Incremental-Refresh.before.m'
        $afterPath  = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Databricks-Incremental-Refresh.after.m'
        $configPath = Join-Path $RepoRoot 'configurations/Databricks.json'

        $rules = Get-EnabledRules -ConfigPath $configPath
        $rules.Count | Should -BeGreaterThan 0

        $before   = Read-FixtureText -Path $beforePath
        $expected = Read-FixtureText -Path $afterPath
        $actual   = Update-MExpression -Expression $before -UpdateRules $rules -ModuleRoot $RepoRoot
        $actual   = $actual -replace "`r`n", "`n"

        $actual | Should -Be $expected
    }

    It 'applies the Databricks-Native-Query rules end-to-end' {
        $beforePath = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Databricks-Native-Query.before.m'
        $afterPath  = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Databricks-Native-Query.after.m'
        $configPath = Join-Path $RepoRoot 'configurations/Databricks.json'

        $rules = Get-EnabledRules -ConfigPath $configPath
        $rules.Count | Should -BeGreaterThan 0

        $before   = Read-FixtureText -Path $beforePath
        $expected = Read-FixtureText -Path $afterPath
        $actual   = Update-MExpression -Expression $before -UpdateRules $rules -ModuleRoot $RepoRoot
        $actual   = $actual -replace "`r`n", "`n"

        $actual | Should -Be $expected
    }

    It 'applies the HMS rules end-to-end' {
        $beforePath = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/HMS.before.m'
        $afterPath  = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/HMS.after.m'
        $configPath = Join-Path $RepoRoot 'configurations/HMS.json'

        $rules = Get-EnabledRules -ConfigPath $configPath
        $rules.Count | Should -BeGreaterThan 0

        $before   = Read-FixtureText -Path $beforePath
        $expected = Read-FixtureText -Path $afterPath
        $actual   = Update-MExpression -Expression $before -UpdateRules $rules -ModuleRoot $RepoRoot
        $actual   = $actual -replace "`r`n", "`n"

        $actual | Should -Be $expected
    }

    It 'applies the Redshift rules end-to-end' {
        $beforePath = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Redshift.before.m'
        $afterPath  = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Redshift.after.m'
        $configPath = Join-Path $RepoRoot 'configurations/Redshift.json'

        $rules = Get-EnabledRules -ConfigPath $configPath
        $rules.Count | Should -BeGreaterThan 0

        $before   = Read-FixtureText -Path $beforePath
        $expected = Read-FixtureText -Path $afterPath
        $actual   = Update-MExpression -Expression $before -UpdateRules $rules -ModuleRoot $RepoRoot
        $actual   = $actual -replace "`r`n", "`n"

        $actual | Should -Be $expected
    }

    It 'applies the Snowflake rules end-to-end' {
        $beforePath = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Snowflake.before.m'
        $afterPath  = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Snowflake.after.m'
        $configPath = Join-Path $RepoRoot 'configurations/Snowflake.json'

        $rules = Get-EnabledRules -ConfigPath $configPath
        $rules.Count | Should -BeGreaterThan 0

        $before   = Read-FixtureText -Path $beforePath
        $expected = Read-FixtureText -Path $afterPath
        $actual   = Update-MExpression -Expression $before -UpdateRules $rules -ModuleRoot $RepoRoot
        $actual   = $actual -replace "`r`n", "`n"

        $actual | Should -Be $expected
    }

    It 'applies the SqlServer rules end-to-end' {
        $beforePath = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/SqlServer.before.m'
        $afterPath  = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/SqlServer.after.m'
        $configPath = Join-Path $RepoRoot 'configurations/SqlServer.json'

        $rules = Get-EnabledRules -ConfigPath $configPath
        $rules.Count | Should -BeGreaterThan 0

        $before   = Read-FixtureText -Path $beforePath
        $expected = Read-FixtureText -Path $afterPath
        $actual   = Update-MExpression -Expression $before -UpdateRules $rules -ModuleRoot $RepoRoot
        $actual   = $actual -replace "`r`n", "`n"

        $actual | Should -Be $expected
    }

    It 'applies the Synapse rules end-to-end' {
        $beforePath = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Synapse.before.m'
        $afterPath  = Join-Path $RepoRoot 'tests/Fixtures/MExpressions/Synapse.after.m'
        $configPath = Join-Path $RepoRoot 'configurations/Synapse.json'

        $rules = Get-EnabledRules -ConfigPath $configPath
        $rules.Count | Should -BeGreaterThan 0

        $before   = Read-FixtureText -Path $beforePath
        $expected = Read-FixtureText -Path $afterPath
        $actual   = Update-MExpression -Expression $before -UpdateRules $rules -ModuleRoot $RepoRoot
        $actual   = $actual -replace "`r`n", "`n"

        $actual | Should -Be $expected
    }
}
