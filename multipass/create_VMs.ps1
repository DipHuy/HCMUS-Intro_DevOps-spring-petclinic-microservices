$MasterName = "master"
$WorkerName = "worker"
$MasterCloudInit = Join-Path $PSScriptRoot "cloud-init-master.yaml"
$WorkerCloudInit = Join-Path $PSScriptRoot "cloud-init-worker.yaml"
$Image = "22.04"
$CPU = 2
$Memory = "2G"
$Disk = "10G"

Write-Host "Creating Master VM..."

multipass launch $Image --name $MasterName --cpus $CPU --memory $Memory --disk $Disk --cloud-init $MasterCloudInit
Write-Host "Master VM created."

Write-Host "----------"

Write-Host "Creating Worker VM..."
multipass launch $Image --name $WorkerName --cpus $CPU --memory $Memory --disk $Disk --cloud-init $WorkerCloudInit
Write-Host "Worker VM created."

$masterIp = (multipass info $MasterName | Select-String "IPv4").ToString().Split()[1]
$workerIp = (multipass info $WorkerName | Select-String "IPv4").ToString().Split()[1]

multipass exec $MasterName -- sudo bash -c "echo '$masterIp $MasterName' >> /etc/hosts"
multipass exec $MasterName -- sudo bash -c "echo '$workerIp $WorkerName' >> /etc/hosts"

multipass exec $WorkerName -- sudo bash -c "echo '$masterIp $MasterName' >> /etc/hosts"
multipass exec $WorkerName -- sudo bash -c "echo '$workerIp $WorkerName' >> /etc/hosts"

Write-Host "Joining $WorkerName to $MasterName cluster"
$joinCommand = (
    multipass exec $MasterName -- sudo kubeadm token create --print-join-command
).Trim()
multipass exec $WorkerName -- sudo bash -c "$joinCommand"


Write-Host "VMs created:"
multipass info $MasterName
Write-Host "----------"
multipass info $WorkerName

