function Write-MigrationLog {
    <#
    .SYNOPSIS
    Writes a timestamped, colored message to the host using the information stream.

    .DESCRIPTION
    Uses Write-Information with InformationAction=Continue so that the output is part
    of the information stream (capturable, redirectable) rather than Write-Host. Color
    is controlled through the Level parameter so callers never need to know colors.

    When the parent script wraps the call in Start-Transcript / Stop-Transcript, all
    output is also captured to the log file.

    .PARAMETER Message
    Text to emit.

    .PARAMETER Level
    Classification that drives console color:
      Info, Success, Warning, Error, Debug, Section, Stat.

    .PARAMETER NoTimestamp
    Suppress the leading ISO-8601 timestamp (used for final statistics lines).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Position = 1)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug', 'Section', 'Stat')]
        [string]$Level = 'Info',

        [Parameter()]
        [switch]$NoTimestamp
    )

    $color = switch ($Level) {
        'Info'    { [System.ConsoleColor]::Gray }
        'Success' { [System.ConsoleColor]::Green }
        'Warning' { [System.ConsoleColor]::Yellow }
        'Error'   { [System.ConsoleColor]::Red }
        'Debug'   { [System.ConsoleColor]::Cyan }
        'Section' { [System.ConsoleColor]::Blue }
        'Stat'    { [System.ConsoleColor]::Magenta }
    }

    $formatted = if ($NoTimestamp) {
        $Message
    } else {
        '{0} {1}' -f (Get-Date -Format s), $Message
    }

    $record = [System.Management.Automation.HostInformationMessage]@{
        Message         = $formatted
        ForegroundColor = $color
        NoNewline       = $false
    }

    Write-Information -MessageData $record -InformationAction Continue -Tags 'PBIMigration'
}
