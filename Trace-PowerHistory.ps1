function Trace-PowerHistory
{
    <#
    .Synopsis
        Traces additional information into the PowerShell history
    .Description
        Trace-PowerHistory traces additional information or objects into the PowerShell history.

        Input piped into the Trace-PowerHistory will be passed thru and added to the PowerShell history
        into a custom property -Name (defaulting to Output)

        Additional information can be added in a -Property dictionary.

        Tags can be added with -Tag.
    .Link
        Get-PowerHistory
    .Example
        Trace-PowerHistory
    #>
    [OutputType([Nullable])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', "", Justification = 'Functionality Most Be Global')]
    param(
    # The InputObject.  Values in this object will be saved to the history for a given invocation ID.
    [Parameter(ValueFromPipeline)]
    [PSObject]
    $InputObject,

    # The name of the property that will store the input.  By default, Output.
    [string]
    $Name = 'Output',

    # Additional properties to write to the history
    [Alias('Properties')]
    [Collections.IDictionary]
    $Property,

    # Additional tags to add to the history.
    [Alias('Tags')]
    [string[]]
    $Tag,

    # The history ID.  By default, information will be traced to the current history ID.
    [long]
    $ID = $MyInvocation.HistoryId
    )

    begin {
        #region Create PowerHistory and $PowerHistory[$id]
        if (-not $Global:PowerHistory) {
            $Global:PowerHistory = [Collections.Generic.Dictionary[string, PSObject]]::new([StringComparer]::OrdinalIgnoreCase)
        }

        if (-not $Global:PowerHistory[$id]) {
            $Global:PowerHistory[$id] = [Ordered]@{}
        }


        #endregion Create PowerHistory and $PowerHistory[$id]

    }

    process {
        #region PassThru and Trace
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            if (-not $Global:PowerHistory[$id].$name) {
                $Global:PowerHistory[$id].$name = [Collections.Generic.List[PSObject]]::new()
            }
            $InputObject
            $Global:PowerHistory[$id].$Name.Add($InputObject)
        }
        #endregion PassThru and Trace
    }

    end {
        if ($Property) {
            foreach ($kv in $Property.GetEnumerator()) {
                $Global:PowerHistory[$id][$kv.Key] = $kv.Value
            }
        }
        if ($Tag) {
            if ($Global:PowerHistory[$id]["Tags"]) {
                $Global:PowerHistory[$id]["Tags"] =
                    @($Tag + $Global:PowerHistory[$ID]["Tags"] | Select-Object -Unique)
            } else {
                $Global:PowerHistory[$id]["Tags"] = $Tag
            }

        }
    }
}
