function Get-OldScheduledTask ($ComputerName){

$Array = @()
$path = "\\$computername\c$\Windows\System32\Tasks"
    $tasks = Get-ChildItem -Path $path -File

    if ($tasks)
    {
        Write-Verbose -Message "I found $($tasks.count) tasks for $computername" -Verbose
    }

    foreach ($item in $tasks)
    {
        $AbsolutePath = $path + "\" + $item.Name
        $task = [xml] (Get-Content $AbsolutePath)
        [STRING]$check = $task.Task.Principals.Principal.UserId

        if ($check)
        {
          $object = [pscustomobject]@{
            ComputerName = $computername
            Item         = $item
            Command      = $task.task.Actions.Exec.Command
            Arguments    = $task.task.Actions.Exec.Arguments
            UserContext  = $check
            }
        $Array += $object
        }

    }
$Array
}