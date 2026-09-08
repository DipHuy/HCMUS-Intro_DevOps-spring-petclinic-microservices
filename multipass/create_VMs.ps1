$MasterName = "master"
$WorkerName = "worker"
$MasterCloudInit = Join-Path $PSScriptRoot "cloud-init-master.yaml"
$WorkerCloudInit = Join-Path $PSScriptRoot "cloud-init-worker.yaml"
$Image = "22.04"
$CPU = 2
$MasterMemory = "2G"
$WorkerMemory = "5G"
$Disk = "10G"

Write-Host "Creating Master VM..."
multipass launch $Image --name $MasterName --cpus $CPU --memory $MasterMemory --disk $Disk --cloud-init $MasterCloudInit
multipass exec $MasterName -- cloud-init status --wait
Write-Host "Master VM created."

Write-Host "----------"

Write-Host "Creating Worker VM..."
multipass launch $Image --name $WorkerName --cpus $CPU --memory $WorkerMemory --disk $Disk --cloud-init $WorkerCloudInit
multipass exec $WorkerName -- cloud-init status --wait
Write-Host "Worker VM created."

# Join the worker node to the master node
Write-Host "Joining $WorkerName to $MasterName cluster"
$joinCommand = (
    multipass exec $MasterName -- sudo kubeadm token create --print-join-command
).Trim()
multipass exec $WorkerName -- sudo bash -c "$joinCommand"


Write-Host "VMs created:"
multipass info $MasterName
Write-Host "----------"
multipass info $WorkerName

Write-Host "All nodes are Ready."
