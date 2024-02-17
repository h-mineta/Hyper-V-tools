#仮想マシン名
$vm = "VM-Name"

$result_vm = Get-VM -Name $vm
if (!$result_vm) {
    Write-output("[ERROR] 指定されたVMが見つかりません")
    return
}

$result = Get-VMGpuPartitionAdapter -VMName $vm

if ($result.InstancePath) {
    Remove-VMGpuPartitionAdapter -VMName $vm
}
