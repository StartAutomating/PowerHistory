function Clear-PowerHistory
{
    <#
    .Synopsis
        Deletes entries from the PowerShell history
    .Description
        Deletes commands from the command history, as well any additional information associated with that history item.
    .Example
        Clear-PowerHistory
    .Link
        Get-PowerHistory
    #>
    [CmdletBinding(DefaultParameterSetName='IDParameter', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkID=135199')]
    [OutputType([Nullable])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', "", Justification = 'Functionality Most Be Global')]
    param(
    # Specifies the history IDs of commands that this cmdlet deletes.
    # To find the history ID of a command, use the Get-History cmdlet.
    [Parameter(ParameterSetName='IDParameter',
        Position=0,
        HelpMessage='Specifies the ID of a command in the session history.Clear history clears only the specified command',
        ValueFromPipelineByPropertyName)]
    [ValidateRange(1, 9223372036854775807)]
    [long[]]
    $Id,

    # Specifies commands that this cmdlet deletes. If you enter more than one string, Clear-PowerHistory deletes commands that have any of the strings.
    [Parameter(ParameterSetName='CommandLineParameter', HelpMessage='Specifies the name of a command in the session history')]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $CommandLine,

    # If provided, will only clear the provided properties from PowerHistory, and will not clear the underlying history item.
    [Alias('Properties')]
    [string[]]
    $Property)

    begin
    {
        $getHistoryCmd = $ExecutionContext.SessionState.InvokeCommand.GetCommand('Get-History','Cmdlet')
    }

    process
    {
        #region If No Parameters are provided
        if (-not $PSBoundParameters.Count) { # If no parameters were provided
            Clear-History # clear the history.
            if (-not $Global:PowerHistory) { # Then create or clear the PowerHistory dictionary, as needed.
                $Global:PowerHistory = [Collections.Generic.Dictionary[string, PSObject]]::new([StringComparer]::OrdinalIgnoreCase)
            } elseif ($Global:PowerHistory.Clear) {
                $Global:PowerHistory.Clear()
            }
            return # Then return.
        }
        #endregion If No Parameters are provided

        $ghSplat = @{} + $PSBoundParameters # Copy the bound parameters
        foreach ($k in $PSBoundParameters.Keys) { # and walk thru each.
            if (-not $getHistoryCmd.Parameters[$k]) { # If the parameter isn't in Get-History,
                $ghSplat.Remove($k) # remove it.
            }
        }


        #region Call Get-History
        . { # Call Get-History in a script block so we stream
            if ($CommandLine) {
                Get-History @ghSplat |
                    Where-Object CommandLine -In $CommandLine
            } else {
                Get-History @ghSplat
            }
        } |
        #endregion Call Get-History
        #region Clear History Entries or Properties
        . {
            begin {
                $allIds = [Collections.ArrayList]::new()
            }
            process {
                if ($property){
                    foreach ($prop in $property) {
                        if ($Global:PowerHistory[$_.ID] -is [Collections.IDictionary]) {
                            $null = $Global:PowerHistory[$_.ID].Remove($prop)
                        }
                        elseif ($Global:PowerHistory[$_.ID].psobject.Properties -and
                            $Global:PowerHistory[$_.ID].psobject.Properties[$prop]) {
                            $Global:PowerHistory[$_.ID].psobject.Properties.Remove($prop)
                        }
                    }
                } else {
                    $null = $allIds.Add($_.ID)
                    $Global:PowerHistory[$_.ID] = $null
                }
            }
            end {
                if ($allIDs) {
                    Clear-History -Id $allIDS.ToArray()
                }
            }
        }
    }
}


