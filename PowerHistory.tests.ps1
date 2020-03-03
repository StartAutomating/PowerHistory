describe PowerHistory {
    context 'Add-PowerHistory' {
        it 'Adds Commands to the PowerShell History' {
            [PSCustomObject]@{
                CommandLine = 'Get-PowerHistory'
                StartExecutionTime = [DateTime]::Now.AddSeconds(-1)
                EndExecutionTime = [DateTime]::Now
                Extra = 'Information'
            } | Add-PowerHistory -Property @{More='Data'}

            $ph = Get-PowerHistory -Count 1
            $ph.RunTime | should be ([Timespan]::FromSeconds(1))
            $ph.CommandLine | should be Get-PowerHistory
        }

        it 'Can add additional -Property' {
            [PSCustomObject]@{
                CommandLine = 'Get-PowerHistory'
                StartExecutionTime = [DateTime]::Now.AddSeconds(-1)
                EndExecutionTime = [DateTime]::Now
            } | Add-PowerHistory -Property @{More='Data'}
            $ph = Get-PowerHistory -Count 1
            $ph.More | should be Data

        }

        it 'Will add a -Property that is piped in, but is not a parameter for Add-PowerHistory' {
            [PSCustomObject]@{
                CommandLine = 'Get-PowerHistory'
                StartExecutionTime = [DateTime]::Now.AddSeconds(-1)
                EndExecutionTime = [DateTime]::Now
                Extra = 'Information'
            } | Add-PowerHistory -Property @{More='Data'}
            $ph = Get-PowerHistory -Count 1
            $ph.Extra | should be Information
        }
    }

    context Clear-PowerHistory {
        it 'Can clear a -Property from history' {
            Clear-PowerHistory -Property Extra, More
            $ph = Get-PowerHistory -Count 1
            $ph.Extra | should be $null
        }
        it 'Can clear by -ID' {
            $h = Get-History -Count 1
            Clear-PowerHistory -Id $h.id
            $h2 = Get-History -Count 1
            $h2.id | should not be $h.id
        }

        it 'Can clear by -CommandLine' {
            Clear-PowerHistory -CommandLine 'Get-PowerHistory'
        }

        it 'Can clear the whole history' {
            Clear-PowerHistory
        }
    }

    context Get-PowerHistory {
        it "Gets PowerShell's History Information + Any Additional Information" {
            [PSCustomObject]@{
                CommandLine = '$ph = Get-PowerHistory'
                StartExecutionTime = [DateTime]::Now.AddSeconds(-1)
                EndExecutionTime = [DateTime]::Now
            } | Add-PowerHistory -Property @{More='Data'}


            $ph = Get-PowerHistory -Count 1
            $ph.RunTime | should begreaterthan ([Timespan]::FromSeconds(0))
        }

        it 'Can get history items that use a -Module' {
            $ph = Get-PowerHistory -Module PowerHistory -Count 1
            $moduleNames = $ph.Modules |
                Select-Object -ExpandProperty Name

            if ($moduleNames -notcontains 'PowerHistory') {
                throw "Expected Modules [$($modulenames)] to contain 'PowerHistory'"
            }
        }

        it 'Can get history items that use a -Command' {
            $ph = Get-PowerHistory -Command Get-PowerHistory -Count 1
            $cmdNames = $ph.Commands | Select-Object -ExpandProperty Name
            if ($cmdNames -notcontains 'Get-PowerHistory') {
                throw "Expected Commands [$cmdNames] to contain 'Get-PowerHistory'"
            }
        }

        it 'Can get history items that use a -Variable' {
            $ph = Get-PowerHistory -Variable ph -Count 1
            $varNames = $ph.Variables
            if ($varNames -notcontains 'ph') {
                throw "Expected Variables [$varNames] to contain 'ph'"
            }
        }

        it 'Can get history items have have a -Property' {
            $ph = Get-PowerHistory -Property RunTime -Count 1
            $ph.Runtime | should begreaterthan ([TimeSpan]::FromSeconds(0))
        }
    }

    context Invoke-PowerHistory {
        it 'Will invoke a previous history item' {
            Invoke-PowerHistory
        }
    }

    context Trace-PowerHistory {
        it "Can trace a piped in object into a property in history" {
            $h = Get-History -Count 1

            1,2,3 | Trace-PowerHistory -Name OneTwoThree -ID $h.Id

            $ph = Get-PowerHistory -Id $h.Id
            $ph.OneTwoThree | should be (1,2,3)
        }

        it 'Can add a -Tag or -Property' {
            $h = Get-History -Count 1

            Trace-PowerHistory -ID $h.Id -Tag "You'reIt" -Property @{
                Extra = 'Extra'
            }

            $ph = Get-PowerHistory -Id $h.Id
            $ph.Extra | should be Extra
            $ph.Tags | should be "You'reIt"
        }

        it "Won't clobber existing tags" {
            $h = Get-History -Count 1

            Trace-PowerHistory -ID $h.Id -Tag "You'reIt" -Property @{
                Extra = 'Extra'
            }

            Trace-PowerHistory -Tag "YouToo"-ID $h.id

            $ph = Get-PowerHistory -Id $h.Id
            $ph.Tags | should be ("You'reIt","YouToo")
        }
    }

    context Sync-PowerHistory {
        it "Synchronizes the PowerHistory with PowerShell's History" {
            Sync-PowerHistory
            $ph = Get-PowerHistory -Count 1
            $ph.RunTime | should begreaterthan ([Timespan]::FromSeconds(0))

        }

        it 'Can infer assignments, variables, modules, and commands' {
            Add-PowerHistory -CommandLine '$PH = Get-PowerHistory' -StartExecutionTime ([DateTime]::Now) -EndExecutionTime ([DateTime]::Now.AddSeconds(1))

            $ph = Get-PowerHistory -Count 1
            $ph.Variables | should be ph
            $ph.Assignments | should be ph
            $ph.Commands | Select-Object -ExpandProperty Name | should be Get-PowerHistory

            $gph = $ExecutionContext.SessionState.InvokeCommand.GetCommand('Get-PowerHistory','Function')
            $ph.Modules | should be $gph.Module
        }
    }
}
