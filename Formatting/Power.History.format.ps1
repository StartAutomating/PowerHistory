Write-FormatView -TypeName Power.History -Property ID, RunTime, CommandLine -Wrap -VirtualProperty @{
    RunTime = { 
        try { 
            $runtimeStr= $_.RunTime.ToString()
            if ($runtimeStr.Length -gt 12) {
                $runtimeStr.Substring(0,12) 
            } else {
                $runtimeStr
            }
        }
        catch { "00:00:00.000"}
    }
} -Width 5, 12

Write-FormatView -TypeName Power.History -Action {
    @(
        $historyEntry = $_
        $statusLine = '-ID:' + $_.ID + ' # ( ' + $_.ExecutionStatus + ' ['+ $_.RunTime +'] )'
        if ($_.ExecutionStatus -ne 'Completed') {
            . $SetOutputStyle -ForegroundColor '#ff0000'
        } else {
            . $SetOutputStyle -ForegroundColor '#00ff00'
        }

        . $heading $statusLine -Level 2
        . $clearOutputStyle
        [Environment]::NewLine 
        $_.CommandLine
        [Environment]::NewLine
        $properties = 
        @(foreach ($prop in $historyEntry.psobject.properties) {
            if ('CommandLine', 'EndExecutionTime','ExecutionStatus', 'Id', 'StartExecutionTime', 'RunTime' -notcontains $prop.Name) {
                $prop  
            }
        })
        if ($properties) {
            
        }
    ) -join ''
}
