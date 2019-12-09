#!/bin/bash
# az CLI wrapper
# Creates a data disk snapshot with a timestamp in the name 
# $2 space separated string
resourceGroup=$1
vmsList=$2
timeStamp=$(date +%Y%m%d%H%M)
for vm in $vmsList; do
    snapshotName=""
    echo "Processing ${vm}"
    dataDisksList=$(az vm show -g $resourceGroup -n $vm --query 'storageProfile.dataDisks[].name' -o tsv)
    for diskName in $dataDisksList; do
        echo "Found ${diskName}"
    done
    for diskName in $dataDisksList; do
        snapshotName="${vm}-${diskName}-${timeStamp}"
        echo "Creating ${snapshotName} for datadisk ${diskName}"
        az snapshot create -g $resourceGroup --source "$diskName" --name $snapshotName
    done
done
