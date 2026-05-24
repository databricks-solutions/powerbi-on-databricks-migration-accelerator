#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $CallbacksRoot = Join-Path -Path $PSScriptRoot -ChildPath '../../src/Callbacks'
    Import-Module (Join-Path -Path $CallbacksRoot -ChildPath 'Resolve-TableNameMapping.psm1') -Force
}

Describe 'Resolve-TableNameMapping' {
    It 'rewrites Schema and Table when a mapping exists' {
        $pattern = 'Schema="(?<Schema>[^"]+)",Item="(?<Table>[^"]+)"'
        $match   = [regex]::Match('Schema="dbo",Item="DimAccount"', $pattern)
        Resolve-TableNameMapping -Match $match |
            Should -Be 'Schema="dbo_new",Item="DimAccount_new"'
    }

    It 'passes through unchanged when no mapping matches' {
        $pattern = 'Schema="(?<Schema>[^"]+)",Item="(?<Table>[^"]+)"'
        $match   = [regex]::Match('Schema="sales",Item="customers"', $pattern)
        Resolve-TableNameMapping -Match $match |
            Should -Be 'Schema="sales",Item="customers"'
    }

    It 'preserves the separator between Schema and Table for dotted references' {
        $pattern = '"(?<Schema>[^"]+)"\."(?<Table>[^"]+)"'
        $match   = [regex]::Match('"dbo"."DimAccount"', $pattern)
        Resolve-TableNameMapping -Match $match |
            Should -Be '"dbo_new"."DimAccount_new"'
    }

    It 'preserves the separator for unmapped dotted references' {
        $pattern = '"(?<Schema>[^"]+)"\."(?<Table>[^"]+)"'
        $match   = [regex]::Match('"sales"."customers"', $pattern)
        Resolve-TableNameMapping -Match $match |
            Should -Be '"sales"."customers"'
    }

    It 'handles matches where the full value spans beyond the named groups' {
        $pattern = '\[Schema=(?<Schema>[^,]+),Table=(?<Table>[^\]]+)\]'
        $match   = [regex]::Match('prefix[Schema=dbo,Table=DimAccount]suffix', $pattern)
        Resolve-TableNameMapping -Match $match |
            Should -Be '[Schema=dbo_new,Table=DimAccount_new]'
    }
}
