#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath '../../src'
    . (Join-Path -Path $ModuleRoot -ChildPath 'Private/Get-EffectiveConfigValue.ps1')
}

Describe 'Get-EffectiveConfigValue' {
    It 'returns the value from the most specific config when set there' {
        $dataset = [pscustomobject]@{ Backup = $true }
        $parent  = [pscustomobject]@{ Backup = $false }
        $global  = [pscustomobject]@{ Backup = $false }

        Get-EffectiveConfigValue -Path 'Backup' -Configs @($dataset, $parent, $global) |
            Should -BeTrue
    }

    It 'falls back to parent when dataset omits the property' {
        $dataset = [pscustomobject]@{ Other = 1 }
        $parent  = [pscustomobject]@{ Backup = $true }
        $global  = [pscustomobject]@{ Backup = $false }

        Get-EffectiveConfigValue -Path 'Backup' -Configs @($dataset, $parent, $global) |
            Should -BeTrue
    }

    It 'falls back to global when dataset and parent omit the property' {
        $dataset = [pscustomobject]@{ Other = 1 }
        $parent  = [pscustomobject]@{ Other = 2 }
        $global  = [pscustomobject]@{ Backup = $true }

        Get-EffectiveConfigValue -Path 'Backup' -Configs @($dataset, $parent, $global) |
            Should -BeTrue
    }

    It 'skips null configs in the chain' {
        $global  = [pscustomobject]@{ Backup = $true }

        Get-EffectiveConfigValue -Path 'Backup' -Configs @($null, $null, $global) |
            Should -BeTrue
    }

    It 'returns $null when the property is not found anywhere' {
        $global = [pscustomobject]@{ Other = 1 }

        Get-EffectiveConfigValue -Path 'Backup' -Configs @($null, $global) |
            Should -BeNullOrEmpty
    }

    It 'resolves nested property paths (Properties.CompatibilityLevel)' {
        $dataset = [pscustomobject]@{ Properties = [pscustomobject]@{ CompatibilityLevel = 1569 } }
        $parent  = [pscustomobject]@{ Properties = [pscustomobject]@{ CompatibilityLevel = 1550 } }

        Get-EffectiveConfigValue -Path 'Properties.CompatibilityLevel' -Configs @($dataset, $parent) |
            Should -Be 1569
    }

    It 'treats explicit $null values as missing and falls through' {
        $dataset = [pscustomobject]@{ Backup = $null }
        $parent  = [pscustomobject]@{ Backup = $true }

        Get-EffectiveConfigValue -Path 'Backup' -Configs @($dataset, $parent) |
            Should -BeTrue
    }
}
