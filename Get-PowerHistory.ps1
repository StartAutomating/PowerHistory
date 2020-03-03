function Get-PowerHistory
{
    <#
    .Synopsis
        Gets commands run in the current session and any attached information.
    .Description
        The Get-PowerHistory cmdlet gets the session history, that is, the list of commands entered during the current session.

        It also returns any additional information related to that history item.

        Additional information can be traced to the history by using Trace-PowerHistory
    .Example
        Get-PowerHistory
    .Example
        Get-PowerHistory -Count 10
    .Example
        Get-PowerHistory -ID ($MyInvocation.HistoryID - 1)
    .Link
        Clear-PowerHistory
    .Link
        Trace-PowerHistory
    .Link
        Invoke-PowerHistory

    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', "", Justification = 'Functionality Most Be Global')]
    [OutputType('Power.History')]
    param(
    <#
    Specifies an array of the IDs of entries in the session history. Get-PowerHistory gets only specified entries.

    If you use both the Id and Count parameters in a command,
    Get-PowerHistory gets the most recent entries ending with the entry specified by the Id parameter.
    #>
    [Parameter(Position=0, ParameterSetName='ByID', ValueFromPipeline)]
    [ValidateRange(1, 9223372036854775807)]
    [long[]]
    $Id,

    <#
    Specifies the name of one or more modules.  Only history entries that use a command from those modules will be returned.
    #>
    [Parameter(Mandatory,ParameterSetName='ByModule')]
    [string[]]
    $Module,

    <#
    Specifies the name of one or more commands.  Only history entries that use these commands will be returned.
    #>
    [Parameter(Mandatory,ParameterSetName='ByCommand')]
    [string[]]
    $Command,

    <#
    Specifies the name of one or more variables.  Only history entries that use these variables will be returned.
    #>
    [Parameter(Mandatory,ParameterSetName='ByVariable')]
    [string[]]
    $Variable,

    <#
    Specifies the name of one or more properties.  Only history entries that use these properties will be returned.
    #>
    [Parameter(Mandatory,ParameterSetName='ByProperty')]
    [Alias('Properties')]
    [string[]]
    $Property,

    <#
    Specifies the number of the most recent history entries that this cmdlet gets. By, default, Get-PowerHistory gets all entries in
    the session history. If you use both the Count and Id parameters in a command, the display ends with the command that is
    specified by the Id parameter.
    #>
    [Parameter(Position=1)]
    [ValidateRange(0, 32767)]
    [int]
    $Count
    )

    begin {
        $getHistory = $ExecutionContext.SessionState.InvokeCommand.GetCommand('Get-History','Cmdlet')
        if (-not $Global:PowerHistory) {
            $Global:PowerHistory = [Collections.Generic.Dictionary[string, PSObject]]::new([StringComparer]::OrdinalIgnoreCase)
        }
    }

    process {
        if ('ByModule', 'ByCommand', 'ByVariable', 'ByProperty' -contains $PSCmdlet.ParameterSetName) {
            Sync-PowerHistory

            $ids = [Collections.Generic.List[long]]::new()
            $c = 0
            $null = :WalkPowerHistory foreach ($kv in $Global:PowerHistory.GetEnumerator()) {
                if ($PSCmdlet.ParameterSetName -eq 'ByModule') {
                    if (-not $kv.Value.Modules) { continue }
                    foreach ($mod in $kv.Value.Modules) {
                        if ($Module -contains $mod.Name) {
                            $ids.Add($kv.Key)
                            if ($Count -and ++$c -ge $count) {
                                break WalkPowerHistory
                            }
                            break
                        }
                    }
                }
                if ($PSCmdlet.ParameterSetName -eq 'ByCommand') {
                    if (-not $kv.Value.Commands) { continue }
                    foreach ($cmd in $kv.Value.Commands) {
                        if ($Command -contains $cmd) {
                            $ids.Add($kv.Key)
                            if ($Count -and ++$c -ge $count) {
                                break WalkPowerHistory
                            }
                            break
                        }
                    }
                }
                if ($PSCmdlet.ParameterSetName -eq 'ByVariable') {
                    if (-not $kv.Value.Variables) { continue }
                    foreach ($var in $kv.Value.Variables) {
                        if ($Variable -contains $var) {
                            $ids.Add($kv.Key)
                            if ($Count -and ++$c -ge $count) {
                                break WalkPowerHistory
                            }
                        }
                    }
                }

                if ($psCmdlet.ParameterSetName -eq 'ByProperty') {
                    foreach ($prop in $property) {
                        if ($null -ne $kv.Value.$prop) {
                            $ids.Add($kv.Key)
                            if ($Count -and ++$c -ge $count) {
                                break WalkPowerHistory
                            }
                        }
                    }
                }
            }
            $PSBoundParameters['ID'] = $Ids.ToArray()
            if ($Count) { # If we have a count, we've already used it,
                $PSBoundParameters.Remove('Count') # so remove it from PSBoundParameters (to make later splatting easier).
            }
        }


        #region Call Get-History
        $getHistoryParameters = @{} + $PSBoundParameters
        foreach ($k in $PSBoundParameters.Keys) {
            if (-not $getHistory.Parameters.$k) {
                $getHistoryParameters.Remove($k)
            }
        }
        $PowerShellHistoryItems = Get-History @getHistoryParameters
        #endregion Call Get-History

        #region Join Get-History with $Global:PowerHistory
        foreach ($historyItem in $PowerShellHistoryItems) {
            $historyItem.pstypenames.clear()
            $historyItem.pstypenames.add('Power.History')

            if (-not $Global:PowerHistory[$historyItem.Id]) {
                Sync-PowerHistory -ID $historyItem.ID
            }

            if ($Global:PowerHistory[$historyItem.ID] -is [Collections.IDictionary]) {
                foreach ($additionalProperty in $Global:PowerHistory[$historyItem.ID].GetEnumerator()) {
                    if (-not $historyItem.psobject.properties[$additionalProperty.Key]) {
                        $historyItem.psobject.properties.add([PSNoteProperty]::new($additionalProperty.Key, $additionalProperty.Value))
                    }
                }
            } else {
                foreach ($additionalProperty in $Global:PowerHistory[$historyItem.ID].psobject.properties) {
                    if (-not $historyItem.psobject.properties[$additionalProperty.Name]) {
                        $historyItem.psobject.properties.add([PSNoteProperty]::new($additionalProperty.Name, $additionalProperty.Value))
                    }
                }
            }

            $historyItem
        }
        #endregion Join Get-History with $Global:PowerHistory
    }

}