# ec2_snaphot_cleaner
Cleaning script to remove unused EC2/EBS snaphots from AWS.

## Dependencies
This is a bash script that needs the aws CLI and the jq package installed.
You should also configure your aws CLI to have the necessary credentials first before executing this tool.

So on ubuntu for example run following commands to set things up:
* `apt-get install awscli jq`
* `aws configure`

## Usage
Make sure script is executable (`chmod +x ec2_snaphot_cleaner.sh`). Then do a `./ec2_snaphot_cleaner.sh`

## Purpose of this Tool
This tool checks for snapshots being used as EBS volumes by machines directly using the `aws describe-volumes` command, it
also checks snaphots being used by AMIs by using the `aws describe-images` command. Snaphots that don't appear in either of
those lists will be deleted!

## Caution / Disclaimer / Warning!
Deleted snaphots can not be recovered! So make sure first this tool actually does what you want! The `aws delete-snaphot` command (being used here) however
makes sure snaphots building on top of each other (sharing blocks) stay intact. See http://docs.aws.amazon.com/cli/latest/reference/ec2/delete-snapshot.html

In my usecase checking only for Volumes and AMIs in use is enough. But if you have for some reason other things depending on snaphots don't run this!

**This script is provided as-is. No guarantees attached!**

## Contribute
If you think this script can be improved or made safer for more usacases feel free to fork it and issue pull requests!
