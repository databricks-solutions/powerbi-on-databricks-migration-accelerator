#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $CallbacksRoot = Join-Path -Path $PSScriptRoot -ChildPath '../../src/Callbacks'
    Import-Module (Join-Path -Path $CallbacksRoot -ChildPath 'ConvertTo-SafeTableName.psm1') -Force
}

Describe 'ConvertTo-SafeTableName' {
    It 'replaces whitespace with underscores' {
        $match = [regex]::Match('Item="Sales Orders"', 'Item="(?<Table>[^"]+)"')
        ConvertTo-SafeTableName -Match $match | Should -Be 'Item="Sales_Orders"'
    }

    It 'replaces hyphens with underscores' {
        $match = [regex]::Match('Item="order-details"', 'Item="(?<Table>[^"]+)"')
        ConvertTo-SafeTableName -Match $match | Should -Be 'Item="order_details"'
    }

    It 'replaces parentheses with underscores' {
        $match = [regex]::Match('Item="orders(historical)"', 'Item="(?<Table>[^"]+)"')
        ConvertTo-SafeTableName -Match $match | Should -Be 'Item="orders_historical_"'
    }

    It 'leaves a clean identifier unchanged' {
        $match = [regex]::Match('Item="customers"', 'Item="(?<Table>[^"]+)"')
        ConvertTo-SafeTableName -Match $match | Should -Be 'Item="customers"'
    }
}
