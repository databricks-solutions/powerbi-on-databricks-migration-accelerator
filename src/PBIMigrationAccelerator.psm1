#Requires -Version 7.4
#Requires -PSEdition Core

Set-StrictMode -Version Latest

$publicFiles  = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public')  -Filter '*.ps1' -ErrorAction SilentlyContinue)
$privateFiles = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -ErrorAction SilentlyContinue)

foreach ($file in @($privateFiles + $publicFiles)) {
    try {
        . $file.FullName
    } catch {
        Write-Error -Message "Failed to dot-source '$($file.FullName)': $_" -ErrorAction Stop
    }
}

if ($publicFiles.Count -gt 0) {
    Export-ModuleMember -Function $publicFiles.BaseName
}
