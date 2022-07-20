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

# Inventory file paths
input_file='/var/www/html/inventory_datafile'
output_file='/var/www/html/inventory.html'

# Utility functions
copy_logs_to_s3_bucket() {
  aws s3 \
  		cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
  		s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar
  echo "Logfiles were archived to s3 bucket : ${s3_bucket}"
}

create_inventory_html_file() {
  html_head="
      <html lang='en'>
      <head>
          <style>
              table {
                  border-collapse: collapse;
                  width: 50%;
                  margin-top: 2%;
                  margin-left:auto;
                  margin-right:auto;
              }
              td {
                  border: 1px solid #bbbbbb;
                  text-align: center;
                  padding: 8px;
              }
              thead {
                  font-weight: bolder;
              }
              h2 {
                  text-align: center;
                  padding-top: 25px;
                  text-decoration: underline;
              }
          </style>
          <title>Automation Project</title>
      </head>
      <body>
      <h2> Logs Archive Inventory </h2>
      <table>
          <thead>
              <td>Log Type</td>
              <td>Time Created</td>
              <td>Type</td>
              <td>Size</td>
          </thead>
"

  html_tail="
      </table>
      </body>
      </html>
"
echo "Creating inventory.html file"
touch ${output_file}
echo ${html_head} > ${output_file}
while read line; do
    echo \<tr\> >> ${output_file}
    for item in $line; do
        echo \<td\>$item\<\/td\> >> ${output_file}
    done
    echo \<\/tr\> >> ${output_file}
done < ${input_file}
echo ${html_tail} >> ${output_file}
echo "Inventory File created."
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

# -------- Start of Task 3 --------- #

# 1. Create Inventory file.
# Log archive data will be updated to 'inventory_datafile'
# HTML file will be created dynamically using the data file.

# Collecting date to prepare inventory file
archive_file=/tmp/${myname}-httpd-logs-${timestamp}.tar
log_type="httpd-logs"
archive_creation_time=${timestamp}
archive_type="tar"
archive_size=$(ls -lrth $archive_file | awk '{print  $5}')

if [[ -f "$input_file" ]];
  then
    echo "Data file exists... Appending data."
    printf "%s\t%s\t%s\t%s\n" $log_type $archive_creation_time $archive_type $archive_size >> $input_file
  else
    echo "Data file is missing... creating data file."
    touch $input_file
    echo "Data file created... Appending data."
    printf "%s\t%s\t%s\t%s\n" $log_type $archive_creation_time $archive_type $archive_size >> $input_file
fi

# Creating new HTML file every time
create_inventory_html_file

# 2. Scheduling cronjob to execute the script daily.
if [ -f "/etc/cron.d/automation" ];
then
	echo "Automation script in place for Daily execution at 01:00 hrs"
else
	touch /etc/cron.d/automation
	printf "0 1 * * * root /root/Automation_Project/auotmation.sh" > /etc/cron.d/automation
fi

# -------- End of Task 3 --------- #
