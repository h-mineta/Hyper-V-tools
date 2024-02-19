#仮想マシン名
$vm = "VM-Name"

#GPU名
$gpu_name = "AMD RADEON*" #最後に*をつけるとワイルドカード検索

#GPU passhtou: $true or $false
#分からないなら$false
$is_passthrou = $false

#------------------------------------------------------------------------------

$result_vm = Get-VM -Name $vm
if (!$result_vm) {
    Write-output("[ERROR] 指定されたVMが見つかりません")
    return
}

$display_device = Get-PnpDevice -PresentOnly |
Where-Object { $_.Status -eq "OK" -and $_.Class -eq "Display" -and $_.FriendlyName -like $gpu_name } |
Select-Object -First 1

$device_id = $display_device.DeviceID -replace "\\", "#"
$device_id = "\\?\" + $device_id + "#*"

$result_gpu = Get-VMHostPartitionableGpu |
Where-Object { $_.Name -like $device_id } |
Select-Object -First 1

if (!$result_gpu) {
    Write-output("[ERROR] 指定されたGPUが見つかりません")
    return
}
$gpu_instance_path = $result_gpu.Name


if ($result_vm.State -eq "Running") {
    Write-output("[ERROR] VMが起動中のため、停止させてください")
    return
}

# 既存のGPUが設定されていればRemove
$remove_check = Get-VMGpuPartitionAdapter -VMName $vm
if ($remove_check.InstancePath) {
    Remove-VMGpuPartitionAdapter -VMName $vm
}

# 指定されたGPUを取り付け
Add-VMGpuPartitionAdapter -VMName $vm -InstancePath $gpu_instance_path
if ($is_passthrou -eq $true) {
    ## Passthru
    Set-VMGpuPartitionAdapter -VMName $vm -Passthru
}
else {
    ## Partition(値は適当)
    Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionVRAM 100000000
    Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionVRAM 100000000
    Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionVRAM 100000000

    Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionEncode 100000000
    Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionEncode 100000000
    Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionEncode 100000000

    Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionDecode 100000000
    Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionDecode 100000000
    Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionDecode 100000000

    Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionCompute 100000000
    Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionCompute 100000000
    Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionCompute 100000000
}

Set-VM -GuestControlledCacheTypes $true -VMName $vm
Set-VM -LowMemoryMappedIoSpace 1Gb -VMName $vm
Set-VM -HighMemoryMappedIoSpace 8GB -VMName $vm

$result = Get-VMGpuPartitionAdapter -VMName $vm
if ($result.InstancePath) {
    Write-output("[INFO] Success.")
    Write-output("[DEBUG] GPU Path :", $gpu_instance_path)
}
else {
    Write-output("[ERROR] Failed.")
}
