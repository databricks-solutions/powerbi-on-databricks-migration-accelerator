#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath '../../src'
    . (Join-Path -Path $ModuleRoot -ChildPath 'Private/Write-MigrationLog.ps1')
    . (Join-Path -Path $ModuleRoot -ChildPath 'Private/Update-MExpression.ps1')
}

Describe 'Update-MExpression' {
    It 'returns the expression unchanged when no rules are provided' {
        $expression = 'let Source = "foo" in Source'
        Update-MExpression -Expression $expression -UpdateRules $null |
            Should -Be $expression
    }

    It 'applies a simple regex replace rule' {
        $rules = @(
            [pscustomobject]@{
                Name           = 'Rename table'
                Enabled        = $true
                Order          = 1
                SearchPattern  = 'Sql\.Database'
                ReplacePattern = 'Databricks.Catalogs'
            }
        )
        $result = Update-MExpression -Expression 'Source = Sql.Database("s","db")' -UpdateRules $rules
        $result | Should -Match 'Databricks\.Catalogs'
    }

    It 'applies rules in the given order' {
        $rules = @(
            [pscustomobject]@{
                Name           = 'first'
                Enabled        = $true
                Order          = 1
                SearchPattern  = 'foo'
                ReplacePattern = 'bar'
            },
            [pscustomobject]@{
                Name           = 'second'
                Enabled        = $true
                Order          = 2
                SearchPattern  = 'bar'
                ReplacePattern = 'baz'
            }
        )
        $result = Update-MExpression -Expression 'foo' -UpdateRules $rules
        $result | Should -Be 'baz'
    }

    It 'ignores rules with an empty SearchPattern' {
        $rules = @(
            [pscustomobject]@{
                Name           = 'empty'
                Enabled        = $true
                Order          = 1
                SearchPattern  = $null
                ReplacePattern = 'x'
            }
        )
        { Update-MExpression -Expression 'hello' -UpdateRules $rules } | Should -Not -Throw
        Update-MExpression -Expression 'hello' -UpdateRules $rules | Should -Be 'hello'
    }

    It 'supports named groups in search and replace patterns' {
        $rules = @(
            [pscustomobject]@{
                Name           = 'named'
                Enabled        = $true
                Order          = 1
                SearchPattern  = '(?<Prefix>Sql)\.Database'
                ReplacePattern = '${Prefix}.Databricks'
            }
        )
        Update-MExpression -Expression 'Sql.Database' -UpdateRules $rules |
            Should -Be 'Sql.Databricks'
    }

    It 'is case-insensitive by default (IgnoreCase option)' {
        $rules = @(
            [pscustomobject]@{
                Name           = 'case'
                Enabled        = $true
                Order          = 1
                SearchPattern  = 'databricks'
                ReplacePattern = 'SPARK'
            }
        )
        Update-MExpression -Expression 'DATABRICKS' -UpdateRules $rules |
            Should -Be 'SPARK'
    }
}
