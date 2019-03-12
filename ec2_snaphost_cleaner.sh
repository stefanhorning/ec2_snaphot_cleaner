#!/bin/bash

# Small tool to delete AWS EC2 Snapshots that are no longer linked to any Volumes or AMIs in use.
# Needs jq and awscli to be installed and configured.
# For example with `apt-get install awscli jq && aws configure`

# Set the env var AWS_PROFILE to run against other AWS account then the default one

# Colors:
RED='\033[0;31m'
NC='\033[0m' # No Color

# Collecting data:
aws_account_id=$(aws sts get-caller-identity | jq -r .Account)
snapshots_used_by_volumes=$(aws ec2 describe-volumes | jq -r .Volumes[].SnapshotId | sort -u)
snapshots_used_by_amis=$(aws ec2 describe-images --owner self | jq -r .Images[].BlockDeviceMappings[].Ebs.SnapshotId | sort -u)
all_snapshots_used=()

vol_count=0
echo "Checking snapshots used by EC2 Volumes"
for snap in ${snapshots_used_by_volumes[@]}; do
  # Make sure snapshot still extits/can be deleted (is owned by us)
  result=$((aws ec2 describe-snapshots --snapshot-id $snap --filters Name=owner-id,Values=$aws_account_id 2> /dev/null || echo '{}') | jq .Snapshots[0])

  if [ "$result" != 'null' ]; then
    printf '.'
    all_snapshots_used+=($snap)
    (( vol_count++ ))
  else
    echo ''
    echo "Found snapshot with id $snap in volume, but snapshot was already deleted or is not owned by this account ($aws_account_id)"
  fi
done
echo 'Done checking Volumes.'
echo ''

ami_count=0
echo "Checking snapshots used by EC2 AMIs"
for snap in ${snapshots_used_by_amis[@]}; do
  if [ $snap != 'null' ]; then
    printf '.'
    all_snapshots_used+=($snap)
    (( ami_count++ ))
  fi
done
echo ''
echo 'Done checking AMIs.'
echo ''

echo "All EC2 snapshots currently in use by either AMIs or Volumes"
echo "------------------------------------------------------------"
used_count=0
all_snapshots_used=($(printf "%s\n" "${all_snapshots_used[@]}" | sort -u)) # sort and keep unique ones only

for snap in ${all_snapshots_used[@]}; do
  echo "$snap"
  (( used_count++ ))
done
echo "# Count: $used_count"
echo " "

echo "All EC2 snapshots currently present on AWS"
echo "------------------------------------------"
all_snaphots_present=$(aws ec2 describe-snapshots --owner self | jq -r .Snapshots[].SnapshotId | sort)
present_count=0
for snap in ${all_snaphots_present[@]}; do
  echo "$snap"
  (( present_count++ ))
done
echo "# Count: $present_count"
echo " "

echo "Will delete $((present_count - used_count)) unused snapshots in 3 seconds. Press Ctrl+C to abort."
sleep 5
echo " "

deleted_count=0
echo "Deleting snapshots not found in list of used ones"
echo "-------------------------------------------------"
for snap in ${all_snaphots_present[@]}; do
  if [[ " ${all_snapshots_used[@]} " =~ " ${snap} " ]]; then
    echo "🗹  Keeping $snap"
  else
    printf "${RED}🗵 ${NC} Deleting $snap \n"
    aws ec2 delete-snapshot --snapshot-id $snap
    (( deleted_count++ ))
  fi
done
echo " "
echo "Deleted $deleted_count snaphots."
