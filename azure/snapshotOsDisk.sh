#!/bin/bash
# az CLI wrapper
# Creates an OS disk snapshot with a timestamp in the name 
# $2 space separated string
resourceGroup=$1
vmsList=$2
timeStamp=$(date +%Y%m%d%H%M)
for vm in $vmsList; do
    echo "Processing ${vm}"
    snapshotName="${vm}-osDisk-${timeStamp}"
    osDiskId=$(az vm show -g $resourceGroup -n $vm --query "storageProfile.osDisk.managedDisk.id" -o tsv)
    echo "Creating ${snapshotName} for $vm"
    az snapshot create -g $resourceGroup --source "$osDiskId" --name $snapshotName
    echo "Wait for ${snapshotName} to be completed"
    az snapshot wait --exists --name $snapshotName --resource-group $resourceGroup
done
