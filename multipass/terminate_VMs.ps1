$MasterName = "master"
$WorkerName = "worker"

multipass delete --purge $MasterName $WorkerName

Write-Host "VMs terminated."
