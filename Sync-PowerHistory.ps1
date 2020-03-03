function Sync-PowerHistory
{
    <#
    .Synopsis
        Synchronizes PowerHistory with Command History
    .Description
        Synchronizes PowerHistory with information that can be automatically inferred from the command history.

        At present, this information is:

        |Name        |Type             | Description                                |
        |------------|-----------------|--------------------------------------------|
        |Assignments | [string[]]      | The variables assigned                     |
        |Commands    | [CommandInfo[]] | The Commands Used                          |
        |CommandsAST | [CommandAst[]]  | The Abstract-Syntax Tree of Commands       |
        |Modules     | [PSModuleInfo[]]| The Modules Used                           |
        |Runtime     | [TimeSpan]      | The RunTime                                |
        |Variables   | [string[]]      | The Variables Used                         |
    .Link
        Get-PowerHistory
    .Example
        Sync-PowerHistory
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    [OutputType([Nullable])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', "", Justification = 'Functionality Most Be Global')]
    param(
    # One or more history IDs.  If no IDs are provided, the current history will be synchronized.
    [Parameter(Mandatory,ParameterSetName='SpecificItem',ValueFromPipelineByPropertyName)]
    [long[]]
    $ID
    )

    begin {
        $allIds = [Collections.Generic.List[long]]::new()
        $inputObjects = [Collections.Generic.List[PSObject]]::new()
    }
    process {
        #region If No ID Is Provided, Go Call Yourself
        if ($PSCmdlet.ParameterSetName -eq 'All') {
            Get-History | Sync-PowerHistory
            return
        }
        #endregion If No ID Is Provided, Go Call Yourself
        #region If an ID is Provided, Accumulate it
        if ($PSCmdlet.ParameterSetName -eq 'SpecificItem') {
            if ($_) {
                $null = $inputObjects.Add($_)
            }
            $allIds.AddRange($ID)
        }
        #endregion If an ID is Provided, Accumulate it

    }

    end {
        $cmdLookup = @{}
        $t, $progId = $allIds.Count, [Random]::new().Next()
        for ($c =0 ; $c -lt $allIds.Count; $c++) {
            if ($t -gt 1) {
                Write-Progress "Syncing History" "$($allIds[$c])" -PercentComplete ($c * 100 / $t) -Id $progId
            }
            $historyItem = $inputObjects[$c]
            if ($historyItem -isnot [Microsoft.PowerShell.Commands.HistoryInfo]) {
                $historyItem = Get-History -Id $allIds[$c] -ErrorAction Ignore
            }

            if (-not $historyItem) { continue }

            if (-not $Global:PowerHistory[$historyItem.Id]) {
                $Global:PowerHistory[$historyItem.Id] = [Ordered]@{}
            }

            if ($Global:PowerHistory[$historyItem.Id] -isnot [Collections.IDictionary]) {
                continue
            }

            if ($Global:PowerHistory[$historyItem.Id].Synchronized) {
                continue
            }

            $phi = $Global:PowerHistory[$historyItem.Id]



            $phi.RunTime = $historyItem.EndExecutionTime - $historyItem.StartExecutionTime

            $script:_FoundVariables = [Collections.Generic.List[string]]::new()
            $script:_FoundAssignments = [Collections.Generic.List[string]]::new()
            $script:_FoundCommands = [Collections.Generic.List[Management.Automation.Language.CommandAst]]::new()
            try {
                $phiScript = [ScriptBlock]::Create($historyItem.CommandLine)



            } catch {
                continue
            }


            if (-not $phiScript) { continue }

            $phiScript.Ast.FindAll({param($ast)
                if ($ast -is [Management.Automation.Language.CommandAst]) {
                    $null = $script:_FoundCommands.Add($ast)
                }
                if ($ast -is [Management.Automation.Language.VariableExpressionAst]) {
                    $null = $script:_FoundVariables.Add($ast.VariablePath)
                }
                if ($ast -is [Management.Automation.Language.AssignmentStatementAst] -and
                    $ast.Left.VariablePath) {

                    $null = $script:_FoundAssignments.Add($ast.Left.VariablePath)
                }

            }, $true)


            $resolvedCmds = [Collections.Generic.List[PSObject]]::new()
            $foundModules = [Collections.Generic.List[Management.Automation.PSModuleInfo]]::new()

            foreach ($cmdAst in $script:_FoundCommands) {
                $cmdName = $cmdAst.CommandElements[0].Value
                if ($cmdName) {
                    if (-not $cmdLookup[$cmdName]) {
                        $cmdLookup[$cmdName] = $ExecutionContext.SessionState.InvokeCommand.GetCommand($cmdName, 'All')
                    }

                    if ($cmdLookup[$cmdName]) {
                        if ($resolvedCmds -notcontains $cmdLookup[$cmdName]) {
                            $resolvedCmds.Add($cmdLookup[$cmdName])
                        }
                        if ($cmdLookup[$cmdName].Module -and
                            $foundModules -notcontains $cmdLookup[$cmdName].Module) {
                            $foundModules.Add($cmdLookup[$cmdName].Module)
                        }
                    }
                }
            }

            $phi.Commands = $resolvedCmds
            $phi.Modules = $foundModules
            $phi.Variables = $script:_FoundVariables
            $phi.Assignments = $script:_FoundAssignments
            $phi.CommandsAST = $script:_FoundCommands
            $phi.Synchronized = $true
        }

        if ($t -gt 1) {
            Write-Progress "Syncing History" "Complete!" -Completed -Id $progId
        }
    }
}
