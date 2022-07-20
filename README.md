# **Automation_Project**

## Repository for DevOps C4 - Course Assignment

### **Task 1** : Create IAM role, Security Group, EC2 instance and S3 bucket. 
EC2 bucket will act as a WebServer with Apache2 installed and ready. 
S3 bucket is used for storing the WebServer logs. 

### **Task 2** : Write an automation bash script named ‘automation.sh’ to do the following:
- Perform an update of the packages
- View and install the packages
- Check, install and ensure that the **apache2** is running and enabled
- Create a tar archive of apache2 access logs and error logs
- Upload to S3 bucket

## The version at this point is tagged Automation-v0.1

### **Task 3** : Bookkeeping and Cron job
- Check for the presence of the inventory.html file in /var/www/html/ and create if not found
- When the script runs, it should create a new entry in the inventory.html file about the following: 
 
  *What log type is archived?*
     
  *Date when the logs were archived*

  *The type of archive*

  *The size of the archive*

-  Create a cron job file in /etc/cron.d/ with the name 'automation' that runs the script /root/<git repository name>/automation.sh every day via the root user
-  Check if a cron job is scheduled or not; if not, then it should schedule a cron job by creating a cron file in the /etc/cron.d/ folder.

## The version at this point is tagged Automation-v0.2
