function Invoke-PowerHistory
{
    <#
    .Synopsis
        Runs commands from the session history and captures their output.
    .Description
        The Invoke-PowerHistory cmdlet runs commands from the session history.

        You can pass objects representing the commands from Get-History to Invoke-PowerHistory,
        or you can identify commands in the current history by using their ID number.

        To find the identification number of a command, use the Get-History cmdlet.
    .Link
        Get-PowerHistory
    .Example
        Invoke-PowerHistory # reruns the most recent command
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', "", Justification = 'Functionality Most Be Global')]
    [OutputType([PSObject])]
    param(
    <#
    Specifies the ID of a command in the history.
    If you omit this parameter, Invoke-PowerHistory runs the last, or most recent, command.
    To find the ID number of a command, use the Get-History cmdlet.
    #>
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Id
    )

    begin {
        $InvocationSettings = [Management.Automation.PSInvocationSettings]::new()
        $InvocationSettings.AddToHistory = $true

        if (-not $Global:PowerHistory) {
            $Global:PowerHistory = [Collections.Generic.Dictionary[string, PSObject]]::new([StringComparer]::OrdinalIgnoreCase)
        }
    }

    process {
        if (-not $id) {
            $id = $MyInvocation.HistoryId - 1
        }
        #region Get and Re-Invoke
        $StartExecutionTime = [DateTime]::Now
        Get-PowerHistory -Id $Id |
            & { process {
                $psCmd = [PowerShell]::Create('CurrentRunspace').AddScript(". {
$($_.commandLine)
} *>&1")
                $psCmd.HistoryString = $_.CommandLine

                $psCmd.Invoke($null, $InvocationSettings)
            } } |
        #endregion Get and Re-Invoke
        #region PassThru and Trace
            & {
                begin {
                    $accumulateOutput = [Collections.ArrayList]::new()

                }
                process {
                    $_
                    $null = $accumulateOutput.Add($_)
                }
                end {
                    $runTime = [DateTime]::Now - $StartExecutionTime
                    $global:PowerHistory[$MyInvocation.HistoryId] = [Ordered]@{
                        RunTime = $runTime
                        Output = $accumulateOutput
                    }
                }
            }
        #endregion PassThru and Trace
    }
}