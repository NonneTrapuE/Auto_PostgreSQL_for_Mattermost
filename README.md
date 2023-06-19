# Auto_PostgreSQL_for_Mattermost
PostgreSQL script to perform fastest installation of Mattermost 


# Warning

It's an experimental script, only tested on Fedora 38 with PostgreSQL 15 and Mattermost 7.10.0

# Notice

For execute script, please use sudo.
You need to create or move script in directory with corrects permissions.
For example: 

``` mv auto_postgres.sh /tmp ```


To execute script : 

``` chmod u+x auto_postgres.sh ```

``` sudo ./auto_postgres.sh ```

# To install Mattermost in other server

To install Mattermost in other server, final step open firewalld service port. If you answer "no", but you want to install Mattermost in other server, open firewalld manually.

``` sudo firewall-cmd --add-service=postegresql --permanent ```

``` sudo firewall-cmd --complete-reload ```
