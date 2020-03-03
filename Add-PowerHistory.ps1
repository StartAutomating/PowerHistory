function Add-PowerHistory
{
    <#
    .Synopsis
        Appends entries to the session history and attaches additional information.
    .Description
        The Add-PowerHistory cmdlet adds entries to the end of the session history,
        that is, the list of commands entered during the current session.
    .Example
        Add-PowerHistory -CommandLine 'Get-PowerHistory' -StartExecutionTime ([DateTime]::Now.AddSeconds(-1) -EndExecutionTime ([DateTime]::Now)
    .Link
        Get-PowerHistory
    .Link
        Sync-PowerHistory
    #>
    [OutputType([Nullable])]
    param(
    # The Command Line
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [string]
    $CommandLine,

    # The time the command started
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [DateTime]
    $StartExecutionTime,

    # The time the command ended
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [DateTime]
    $EndExecutionTime,

    # The execution status
    [Parameter(ValueFromPipelineByPropertyName)]
    [Management.Automation.Runspaces.PipelineState]
    $ExecutionStatus = 'Completed',

    # Any additional properties associated with this history item.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('Properties')]
    [Collections.IDictionary]
    $Property
    )

    process {
        #region Add-History
        $historyItem = [PSCustomObject]@{
            CommandLine=$CommandLine;
            StartExecutionTime=$StartExecutionTime;
            EndExecutionTime=$EndExecutionTime;
            ExecutionStatus=$ExecutionStatus
        } | Add-History -Passthru
        #endregion Add-History

        #region Add -Property from Piped Input
        foreach ($prop in $_.psobject.properties) {
            if ($MyInvocation.MyCommand.Parameters.Keys -notcontains $prop.Name -and $prop.Name -ne 'id') {
                if (-not $Property) {
                    $Property = [Ordered]@{}
                }
                $Property[$prop.Name] = $prop.Value
            }
        }
        #endregion Add -Property from Piped Input

        #region Add to PowerHistory
        $newHistoryId = $historyItem.Id
        Sync-PowerHistory -ID $newHistoryId
        if ($Property) {
            Trace-PowerHistory -ID $newHistoryId -Property $Property
        }
        #endregion Add to PowerHistory
    }
}