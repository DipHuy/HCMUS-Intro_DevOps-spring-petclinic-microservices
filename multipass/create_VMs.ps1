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



Write-Host "Waiting for all Kubernetes nodes to become Ready..."

do {
    Start-Sleep -Seconds 5

    $nodes = multipass exec $MasterName -- kubectl get nodes --no-headers 2>$null

    Write-Host $nodes

} until (
    $nodes -match "$MasterName\s+Ready" -and
    $nodes -match "$WorkerName\s+Ready"
)

Write-Host "All nodes are Ready."

Write-Host "Installing NGINX Ingress..."

multipass exec $MasterName -- helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

multipass exec $MasterName -- helm repo update

multipass exec $MasterName -- helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --kubeconfig=/home/ubuntu/.kube/config --wait --timeout 5m
