PowerHistory adds additional features to PowerShell's history.

It adds useful information about any history item,
and allows you to add extra properties to any history item. 

### Installing PowerHistory

You can clone the PowerHistory repository or Install PowerHistory from the PowerShell Gallery:

~~~
Install-Module PowerHistory -Scope CurrentUser
~~~

### Using PowerHistory

You can use PowerHistory just like Get-History:
~~~
Get-PowerHistory # Gets all history items
~~~

You can also do some more nifty tricks, like find items in history that use a module, command, or variable:

~~~
Get-PowerHistory -Module PowerHistory # Gets previous uses of commands from PowerHistory

Get-PowerHistory -Command Get-PowerHistory # Gets previous runs of Get-PowerHistory

Get-PowerHistory -Variable MyVariable # Gets previous uses of $MyVariable 
~~~


### Tracing to the history

You can store command output in a PowerHistory entry with any given -Name (defaulting to Output), and add additional -Properties or -Tags

~~~
Get-Process | Trace-PowerHistory -Name ActiveProcesses -Property @{TimeStamp=[DateTime]::Now} -Tag Processes
~~~

