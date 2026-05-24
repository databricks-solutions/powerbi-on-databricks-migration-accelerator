#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $RepoRoot   = Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '../..')
    $SchemaPath = Join-Path -Path $RepoRoot -ChildPath 'Configuration.schema.json'
    $SchemaJson = Get-Content -LiteralPath $SchemaPath -Raw
}

Describe 'Configuration.schema.json' {
    It 'is valid JSON' {
        { $SchemaJson | ConvertFrom-Json } | Should -Not -Throw
    }

    It 'validates the root Configuration.json' {
        $configPath = Join-Path -Path $RepoRoot -ChildPath 'Configuration.json'
        $configJson = Get-Content -LiteralPath $configPath -Raw
        Test-Json -Json $configJson -Schema $SchemaJson -ErrorAction SilentlyContinue | Should -BeTrue
    }

    It 'validates every shipped sample config' {
        $samplesRoot = Join-Path -Path $RepoRoot -ChildPath 'configurations'
        $samples     = Get-ChildItem -Path $samplesRoot -Filter '*.json'

        foreach ($sample in $samples) {
            $sampleJson = Get-Content -LiteralPath $sample.FullName -Raw
            $isValid    = Test-Json -Json $sampleJson -Schema $SchemaJson -ErrorAction SilentlyContinue
            $isValid | Should -BeTrue -Because "$($sample.Name) should validate against Configuration.schema.json"
        }
    }
}
