#!/bin/bash

# 1. Perform an update of the package
# Used to re-synchronize the package index files from their sources.
apt update -y
# Used to install the newest versions of all packages currently installed on the system.
apt upgrade -y

# 2. Initializing variables
myname='Suraj'
s3_bucket='upgrad-suraj'
timestamp=$(date '+%d%m%Y-%H%M%S')

# Utility functions
copy_logs_to_s3_bucket() {
  aws s3 \
  		cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
  		s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar
  echo "Logfiles were archived to s3 bucket : ${s3_bucket}"
}

# 3. Install the apache2 package if it is not already installed.
# Using Regex Operator '=~' to check command output contains the expected string.
if [[ $(dpkg --list | grep apache2) =~ 'apache2' ]];
then
  # 4. Ensure that the apache2 service is running.
  echo "Apache2 is installed... checking for its state."
  if [[ $(systemctl status apache2) =~ 'active' ]];
  then
  	echo "Apache2 service is running."
  else
  	echo "Apache2 service is not running... Staring service now."
  	systemctl start apache2
  	echo "Apache2 service is now running."
  fi
  # 5. Ensure that the apache2 service is enabled.
	if [[ $(systemctl status apache2) =~ 'enabled;' ]];
		then
		  echo "Apache2 service is enabled."
		else
		  echo "Apache2 is not enabled... Enabling now."
		  systemctl enable apache2
		  echo "Apache2 is now enabled."
	fi
else
	echo "Apache2 not installed... Installing Apache2 now"
	printf 'Y\n' | apt install apache2
	echo "Apache2 service is installed... Service is running now."
fi

# 6. Creating a tar archive of apache2 access logs and error logs
tar -cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/access.log /var/log/apache2/error.log

# 7. Uploading to S3 bucket
# [Optional] Checking for AWS CLI is installed.
if [[ $(dpkg --list | grep awscli) =~ 'awscli' ]];
	then
		copy_logs_to_s3_bucket
	else
	  echo "awscli was not installed... Installing now."
	  printf 'Y\n' | apt install awscli
	  echo "awscli is now installed."
	  copy_logs_to_s3_bucket
fi
