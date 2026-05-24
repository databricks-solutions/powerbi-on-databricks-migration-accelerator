#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $CallbacksRoot = Join-Path -Path $PSScriptRoot -ChildPath '../../src/Callbacks'
    Import-Module (Join-Path -Path $CallbacksRoot -ChildPath 'ConvertTo-LowerCaseTableName.psm1') -Force
}

Describe 'ConvertTo-LowerCaseTableName' {
    It 'lower-cases the Table named group only' {
        $pattern = 'Item="(?<Table>[^"]+)"'
        $match   = [regex]::Match('Item="CUSTOMER"', $pattern)
        ConvertTo-LowerCaseTableName -Match $match | Should -Be 'Item="customer"'
    }

    It 'returns the same string when the table is already lower case' {
        $pattern = 'Item="(?<Table>[^"]+)"'
        $match   = [regex]::Match('Item="orders"', $pattern)
        ConvertTo-LowerCaseTableName -Match $match | Should -Be 'Item="orders"'
    }

    It 'preserves surrounding content when replacing mixed case' {
        $pattern = 'Item="(?<Table>[^"]+)"'
        $match   = [regex]::Match('Item="LineItem"', $pattern)
        ConvertTo-LowerCaseTableName -Match $match | Should -Be 'Item="lineitem"'
    }
}
