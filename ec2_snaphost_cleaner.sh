#!/bin/bash

# Small tool to delete AWS EC2 Snapshots that are no longer linked to any Volumes or AMIs in use.
# Needs jq and awscli to be installed and configured.
# For example with `apt-get install awscli jq && aws configure`
RED='\033[0;31m'
NC='\033[0m' # No Color
# set this to other profiles you might have in your aws config:
AWS_PROFILE=default

snapshots_used_by_volumes=$(aws ec2 --profile $AWS_PROFILE describe-volumes | jq -r .Volumes[].SnapshotId | sort)
snapshots_used_by_amis=$(aws ec2 --profile $AWS_PROFILE describe-images --owner self | jq -r .Images[].BlockDeviceMappings[].Ebs.SnapshotId | sort)
all_snapshots_used=()

vol_count=0
#echo "Snaphost used by EC2 Volumes"
for snap in ${snapshots_used_by_volumes[@]}; do
#  echo "$snap"
  all_snapshots_used+=($snap)
  (( vol_count++ ))
done
#echo "Count: $vol_count"

ami_count=0
#echo "Snaphots used by EC2 AMIs"
for snap in ${snapshots_used_by_amis[@]}; do
  if [ $snap != 'null' ]; then
#    echo "$snap"
    all_snapshots_used+=($snap)
    (( ami_count++ ))
  fi
done
#echo "Count: $ami_count"
#echo "Total: $(($vol_count + $ami_count))"

echo "All EC2 snapshots currently in use by either AMIs or Volumes"
echo "------------------------------------------------------------"
merged_count=0
all_snapshots_used=($(printf "%s\n" "${all_snapshots_used[@]}" | sort -u)) # sort and keep unique ones only

for snap in ${all_snapshots_used[@]}; do
  echo "$snap"
  (( merged_count++ ))
done
echo "# Count: $merged_count"
echo " "

echo "All EC2 snapshots currently present on AWS"
echo "------------------------------------------"
all_snaphots_present=$(aws ec2 --profile $AWS_PROFILE describe-snapshots --owner self | jq -r .Snapshots[].SnapshotId | sort)
present_count=0
for snap in ${all_snaphots_present[@]}; do
  echo "$snap"
  (( present_count++ ))
done
echo "# Count: $present_count"
echo " "

deleted_count=0
echo "Deleting snapshots not found in list of used ones"
echo "-------------------------------------------------"
for snap in ${all_snaphots_present[@]}; do
  if [[ " ${all_snapshots_used[@]} " =~ " ${snap} " ]]; then
    echo "🗹  Keeping $snap"
  else
    printf "${RED}🗵 ${NC} Deleting $snap \n"
    aws ec2 --profile $AWS_PROFILE delete-snapshot --snapshot-id $snap
    (( deleted_count++ ))
  fi
done
echo " "
echo "Deleted $deleted_count snaphots."
