@{
    Severity = @('Error', 'Warning', 'Information')

    IncludeDefaultRules = $true

    IncludeRules = @(
        'PSAvoidUsingWriteHost'
        'PSUseApprovedVerbs'
        'PSAvoidGlobalVars'
        'PSUseShouldProcessForStateChangingFunctions'
        'PSProvideCommentHelp'
        'PSAvoidUsingCmdletAliases'
        'PSAvoidUsingPositionalParameters'
        'PSAvoidUsingEmptyCatchBlock'
        'PSUseDeclaredVarsMoreThanAssignments'
        #'PSUseConsistentIndentation'
        'PSUseConsistentWhitespace'
        'PSAlignAssignmentStatement'
        'PSUseCorrectCasing'
    )

    ExcludeRules = @(
        'PSUseSingularNouns'
    )

    Rules = @{
        PSUseConsistentIndentation = @{
            Enable          = $true
            IndentationSize = 4
            Kind            = 'space'
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
        }
        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }
        PSProvideCommentHelp = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'before'
        }
    }
}
