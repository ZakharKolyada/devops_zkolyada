**Homework according to the lecture #13 Monitoring Services**

*Description*:

This playbook is only for Ubuntu

*How to use ansible-playbook*:

1. Download the *Monitoring Services.zip* archive
2. Unzip files to one folder
3. Change server IP/user/password in the *inventory.ini* file to your server data
4. Add *ansible_ssh_common_args='-o StrictHostKeyChecking=no'* parameter to the *inventory.ini* file (if needed)
5. Execute the *ansible-playbook -i inventory.ini playbook.yml* command
6. After successful installation the Grafana web interface will be available at http://<your_server>:3000. Default login: admin, password: admin.
