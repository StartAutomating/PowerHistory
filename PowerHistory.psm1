[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', "", Justification = 'Functionality Most Be Global')]
param()
foreach ($file in Get-ChildItem -Path $PSScriptRoot -Filter '*-*.ps1') {
    . $file.FullName
}

Set-Alias aph Add-PowerHistory
Set-Alias gph Get-PowerHistory
Set-Alias tph Trace-PowerHistory
Set-Alias iph Invoke-PowerHistory

if (-not $Global:PowerHistory) {
    $Global:PowerHistory = [Collections.Generic.Dictionary[string, PSObject]]::new([StringComparer]::OrdinalIgnoreCase)
}

Export-ModuleMember -Function *-* -Alias *