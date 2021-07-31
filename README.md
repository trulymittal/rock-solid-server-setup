# Production ready server setup.

## Creating a Linux instance

To create an instance, I will be using Digital Ocean (DO) as its UI is simple and clean to use. In DO world they are called droplets. Though you can use AWS EC2, Linoe, Vultr, etc... whatever you like.

If you dont have an account on DO then use the link (https://m.do.co/c/3208f08b3324) to get 100$ credit to get started.

## Generate a SSH key (if not already done)

Open a terminal and run the following command

```bash
ssh-keygen
```

You will be prompted to save and name the key.

```bash
Generating public/private rsa key pair. Enter file in which to save the key (/Users/USER/.ssh/id_rsa)
```

Next you will be asked to create and confirm a passphrase for the key (highly recommended):

```
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

This will generate two files, by default called id_rsa and id_rsa.pub. Next, add this public key.

Copy the public key in clipboard to be later used when creating a DO droplet.

```bash
cat id_rsa.pub | pbcopy
```

## Create a CENTOS 8.x droplet on digital ocean

I chose the following paramters for my droplet, only the things you need to select are written here, rest everything is default.

| Selection         | Value                                      |
| ----------------- | ------------------------------------------ |
| Image             | CentOS 8.x                                 |
| Plan              | Basic (5$)                                 |
| Add block storage | None                                       |
| Datacenter region | Bangalore (choose which is nearest to you) |
| Authentication    | SSH                                        |

For Adding SSH keys to DO, click NEW SSH key, and follow simple instructions.

Finally click on create Droplet and sit back and relax for a moment.

## SSH into your droplet with **root user**

Get the IP of the droplet from your DO droplets page, and then ssh into it.

```bash
ssh root@XXX.XXX.XXX.XXX
# XXX.XXX.XXX.XXX represents your IP

The authenticity of host '139.59.47.191 (139.59.47.191)' can't be established.
ECDSA key fingerprint is SHA256:rup2QTATg6cOBDcMiP0abSmsOO+4eAMKA4q/Z7O2xVc.
Are you sure you want to continue connecting (yes/no)?

# type yes and press enter
```

Now you will or might get error like this

```bash
Warning: Permanently added '139.59.47.191' (ECDSA) to the list of known hosts.
root@139.59.47.191: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```

Now add the generated ssh key in

```bash
ssh-add ~/.ssh/do_youtube
# Identity added: /Users/killer/.ssh/do_youtube (jhondoe@iMac.local)
```

Finally now you can SSH into your remote machine

```bash
ssh root@XXX.XXX.XXX.XXX
```

Huh, long work, but your droplet is up and running and time to play with it...and make it **production ready**.

### Update the OS using **dnf** package manager (comes pre-install with centos 8.x)

```bash
dnf update -y
```

It will really take sometime, so sit back relax and have a cup of tea ☕️, (Note: I like tea but you can also have coffee or a beer).

### Install packages using **dnf**

```bash
dnf install curl vim git wget '@Development tools' nmap net-tools
```

Once again, it will take sometime, so sit back relax and have a second cup of tea ☕️, (Note: I like tea but you can also have coffee or a beer).

### Adding EPEL to CentOS 8

```bash
dnf install epel-release
dnf upgrade
```

### Start and install automatic updates

```bash
dnf install dnf-automatic -y
systemctl enable --now dnf-automatic.timer
systemctl list-timers *dnf-*
```

### Install Snapd from

(https://snapcraft.io/docs/installing-snapd)

```bash
sudo dnf install snapd -y
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
```

### Setup sudo user with root priveleges

- create a User with your choice of USERNAME, we will make this user have **sudo** access
  ```bash
  adduser USERNAME
  ```
- add this user to the wheel group using `usermod -aG wheel USERNAME` (wheel group is always present in centos and has sudo access)

```bash
  usermod -aG wheel USERNAME
```

- Allow wheel group to have password-less sudo

  - edit file `/etc/sudoers` (using `visudo`)

  ```bash
  visudo /etc/sudoers
  ```

  - `%wheel ALL=(ALL) NOPASSWD: ALL`
  - validate using `/usr/sbin/visudo -cf /etc/sudoers`

    OR

- add a file called USERNAME with the content below to only have this user to use password-less sudo

```bash
visudo /etc/sudoers.d/USERNAME
USERNAME ALL=(ALL) NOPASSWD: ALL
# validate using
/usr/sbin/visudo -cf /etc/sudoers
```

### Set authorized_key for remote user USERNAME using rsync

```
rsync --archive --chown=USERNAME:USERNAME ~/.ssh /home/USERNAME
```

###### OR

```bash
# (700 only current user can Read Write Execute)
# (600 only current user can Read Write)
  su USERNAME
  mkdir .ssh
  chmod 700 .ssh
  touch .ssh/authorized_keys
  chmod 600 .ssh/authorized_keys
# copy **PUBLIC** SSH KEY in this file created above
```

Finally exit out of your remote machine and SSH into your remote machine as this sudouser USERNAME

```bash
ssh USERNAME@XXX.XXX.XXX.XXX
```

### Setup sshd_config

```bash
cd /etc/ssh
cat /etc/ssh/ssh_config
#create a file here like ssh_config.conf
/etc/ssh/ssh_config.d/*.conf
# with following content
PasswordAuthentication no
Permitrootlogin no
# Save and quit and validate...

# optionally, but not recommended to directly edit the sshd_config, though you can
# edit `sshd_config`
# PermitRootLogin no (OR without-password)
# PasswordAuthentication no
# AllowUsers killer (etc...)
# Or you can also use 'DenyUsers' directive to deny particular users, (am not doing it)
# Finally

```

Validate `sshd_config`

```bash
sshd -T -f /etc/ssh/sshd_config
# OR (from any path)
sshd -t
```

Reload SSHD service

```bash
systemctl reload sshd
```

Optionally, for this new user, create ssh public/private to be used on github for private repos.

```bash
# run this command when loggin into ssh with this new user only
ssh-keygen -t ed25519
```

### (Optional) Delete other user **centos**

```bash
userdel centos

# You can also delete that user's home directory and mail spool by using the -r flag with the command
# recommended
userdel -r centos
```

### (Optional) Install **fish** terminal

I recommend installing fish shell, since it prettifies the terminal session and provides with autocompletion and much more.

```bash
sudo dnf install fish -y
# List all present shells
cat /etc/shells
# change shell to fish instead of bash
sudo usermod --shell $(which fish) USERNAME
# exit and ssh again, to use fish shell
```

### Install Nodejs

(https://nodejs.org/en/download/)

There are two options to install nodejs, one is using dnf and other using snaps

1. To see a list of available streams, where **stream** corresponds to the major version of Node.js.
   For example, to install Node.js 14:

```bash
dnf module list nodejs
# Choose the version using:
sudo dnf module enable nodejs:14 -y
sudo dnf module install nodejs:14 -y
node --version
npm --version
```

######OR

2. using snap craft (https://github.com/nodejs/snap)

```
sudo snap install node --classic --channel=14
```

### Setup PM2 (process manager for node applications)

Install and run the startup script

```bash
# ssh as current USER not as root
sudo npm install -g pm2
```

Either use `pm2 startup` and follow the instructions
OR use this script below

Start and enable pm2 as a service

```bash
sudo env PATH=$PATH:/usr/local/bin pm2 startup systemd -u USERNAME --hp /home/USERNAME
```

Check status of pm2

```
systemctl status pm2-USERNAME
```

IMPORTANT NOTE: If the Active status is not **Active: active (running)** and is something like _failed_ or _activating_ , then execute the following commands in order (just for info, this is related to SELINUX), and everything should be fine, else if still it creates a problem you can make an issue in this repo only after trying out the fix.

```bash
# Change to root user
sudo su
# The following start command will timeout
systemctl start pm2-USERNAME
# Then do this
ausearch -c 'systemd' --raw | audit2allow -M my-systemd
semodule -i my-systemd.pp
# NOTE: this is NOT a mistake, it has to be done twice
systemctl start pm2-USERNAME
# Again, the above start command will timeout
ausearch -c 'systemd' --raw | audit2allow -M my-systemd
semodule -i my-systemd.pp
systemctl start pm2-USERNAME
# Finally the above start command will start the pm2 service, and verify it with
systemctl status pm2-USERNAME
# sudo reboot
```

### Start the Nodejs application

- Login as the user created above with root privilages

- Install yarn global packages

```
sudo npm install -g yarn
```

- Starting the Nodejs application

```bash
# Clone the repo any dir, example: inside this folder `~/application`
cd ~/application
git clone REPO_URL application
yarn install
# To start pm2 in cluster mode, ie, to start 2 instances of application use (-i 2) or else simple pm2 start app.js
PORT=4000 pm2 start app.js -n my_app
pm2 save
```

- list application using `pm2 monit`

### NGINX as Reverse proxy

- Install Nginx (make sure epel-release is already installed, though already done above)

```bash
dnf install nginx
```

- **Enable SELinux** for Nginx httpd_t (IMPORTANT)

```bash
semanage permissive -a httpd_t
# OR
sudo setsebool -P httpd_can_network_connect on

# Other SELinux commands
getenforce
# read selinux context (type) of files and processes
# -P = persist setting
sudo setsebool -P httpd_can_network_connect on
# To read home dirs, specially for app public directory served through nginx
sudo setsebool -P httpd_enable_homedirs on
chcon -Rt httpd_sys_content_t /home/USERNAME/app/public
```

- Disable Nginx Server Header

```bash
# nginx.conf

http {
  # Disable emitting nginx version on error pages and in the "Server" response header field
  server_tokens off;
}
```

- create `example.conf` file inside `/etc/nginx/conf.d/`

- Sample server configutaion file are present in templates folder.

### SSL certificates using certbot

(https://certbot.eff.org/lets-encrypt/snap-nginx.html)

- Install snapd, if not already done, install Snapd from (https://snapcraft.io/docs/installing-snapd)

```bash
sudo dnf install snapd -y
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
```

- Install certbot from snapd

```bash
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

- Generate the certificate using the below command

```bash
sudo certbot --nginx -d example.com,www.example.com -n -m youremail@example.com --agree-tos
# --nginx Automatic, GETS and INSTALLS
# -n non-interactive
# -m for emails about certs
```

Test automatic renewal

```bash
sudo certbot renew --dry-run
```

Check renew status timer

```bash
systemctl list-timers *certbot*
```

### Github Webhook support for automated deployments

https://github.com/adnanh/webhook

First create a webhook from repository, is is located under settings of the repo.
_settings → webhook → add webhook_

- add a payload url of your choice (https://example.com/hooks/redeploy-app)
- any secret
- `content-type` to: `application/json`
- just the push event
- active

**payload url**: is the url which will be called whenever a push occurs on your repo (example: https://example.com/hooks/redeploy-app)
**secret**: is the secret used to verify that the url is triggered by github

Only then follow these steps below.

1. Install webhook using binary
   (https://github.com/adnanh/webhook/releases)

```bash
  cd ~
  wget https://github.com/adnanh/webhook/releases/download/2.8.0/webhook-linux-amd64.tar.gz
  # 62ab801c7337a8b83de8d6ae8d7ace81  webhook-linux-amd64.tar.gz
  # Check and verify md5 checksum (use md5 on MacOS and md5sum on linux)
  md5sum webhook-linux-amd64.tar.gz
  tar -xvf webhook-linux-amd64.tar.gz
  sudo mv webhook-linux-amd64/webhook /usr/local/bin
  rm -rf webhook-linux-amd64.tar.gz webhook-linux-amd64
  webhook --version
  # Run below on to test if its able to execute and then close (Ctrl+C)
  webhook -verbose
```

2. Create `redeploy.sh` script inside `~/webhooks` folder (you can choose ur folder name but from now i am considering its called webhooks)

```bash
cd ~
mkdir webhooks
cd webhooks
touch redeploy.sh hooks.json
# change redeploy.sh permissions to be executable
chmod +x redeploy.sh
```

3. Redeploy script `redeploy.sh` is present in templates folder (you can modify according to your needs)

4. `hooks.json` is present in the `templates` folder of this repo (you can modify according to your needs but read documentation)

- Detailed Reference @ https://github.com/adnanh/webhook/blob/master/docs/Hook-Definition.md

  1. id: This is the endpoint used in url, you can change if you want or keep it as is
     Note: In our case when creating a webhook on Github, the webhook url would look something like this:
     https://servername.com/webhooks/github-push
  2. execute-command: Full Path to the redeploy script (not with ~, example: /home/killer/webhooks/redeploy.sh)
  3. command-working-directory: Full Path to the working directory, where this redeploy script needs to be executed, in case of a nodejs application, it should be the place where package.json is placed.

  Refer hooks.json in templates folder

  1. If you don't understand just leave it as is, and ONLY change SOME_SUPER_SECRET_FROM_GITHUB_WHILE_CREATING_WEBHOOK, and only specify the branch name to deploy
  2. Only redeploy on a push to the master branch. Change this value if your branch has a different name

5. Try your hook is testing mode

```bash
cd ~/webhooks
webhook -hooks hooks.json -hotreload -verbose -ip "127.0.0.1" -http-methods post
# Leave the webhook running in verbose mode and try to commit changes and it should work
```

6. If everything above works and you have automated deployment, woo-hoo, time to do some more stuff, i.e. create a systemd service for the same

- create a file called `webhook.service` inside `/etc/systemd/system`
- change permission of file webhook.service to 0644 `chmod 644 webhook.service`
- copy the contents from the `webhook.service` file from the templates folder
  - NOTE:
    - **killer** with the name of user who starts this service, can be USERNAME of logged in ssh user
    - /home/killer/webhooks/hooks.json this is my path, provide a complete path to your hooks.json created above
- Start and enable the service using:
  - `sudo systemctl start webhook.service` (starts the service)
  - `sudo systemctl enable webhook.service` (Enable, so that service is auto-started on reboot)
  - `sudo systemctl status webhook.service` (Check status, and make sure its running and enabled)
- If the service is NOT active, it is due to selinux, use the command below and troubleshoot, and it will provide you with details as to what to execute and IT WILL WORK.
  - `journalctl -xe`
- In case you want to reload/restart/stop/disbale service:
  - `sudo systemctl reload webhook.service`
  - `sudo systemctl restart webhook.service`
  - `sudo systemctl stop webhook.service`
  - `sudo systemctl disable webhook.service`

### Fail2Ban

```bash
# Assuiming you already install epel-repo (which is already done above)
sudo dnf install fail2ban -y
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# To see failed ssh attempts
tail -f /var/log/secure
grep 'sshd.*Failed password for' /var/log/secure
```

Configure Fail2ban settings, create or edit the `/etc/fail2ban/jail.d/jail-sshd.conf` file using a text editor such as vi/vim or nano/emacs, with the contents from file `jail-sshd.conf` inside templated folder, save and exit file, and reload fail2ban

```bash
sudo systemctl reload fail2ban
```

Helper commands for fail2ban (sshd)

```bash
sudo fail2ban-client status sshd
Unban an IP:
sudo fail2ban-client set sshd unbanip x.x.x.x
Ban an IP:
sudo fail2ban-client set sshd banip x.x.x.x
```

### Firewalld commands

```bash
sudo dnf install firewalld

sudo systemctl start firewalld
sudo systemctl enable firewalld

sudo firewall-cmd --add-service http --zone public --permanent
sudo firewall-cmd --add-service https --zone public --permanent

sudo firewall-cmd --reload


# List all ports and services by the following commands
firewall-cmd --list-ports
firewall-cmd --list-services

# Note about: dhcpv6-client which allows incoming DHCP v6 responses to pass - this is the dhcpv6-client rule. If you're not running DHCP v6 on your network or you are using static IP addressing, then you can disable it.

# Close all other services and ports, which are not required
# The command refrence is below
sudo systemctl reload firewalld
sudo systemctl restart firewalld
sudo firewall-cmd --state
sudo firewall-cmd --list-services
sudo firewall-cmd --get-zones
sudo firewall-cmd --zone public --list-all
sudo firewall-cmd --zone=public --permanent --add-service=http
sudo firewall-cmd --remove-service http --zone public
firewall-cmd --get-default-zone
sudo firewall-cmd --zone=public --add-port=3000/tcp
sudo firewall-cmd --zone=public --remove-port=3000/tcp
```

## Timezones and NTP

### Configure Timezones

Our first step is to set our server's timezone. This is a very simple procedure that can be accomplished using the timedatectl command:

- First, take a look at the available timezones by typing:

```bash
sudo timedatectl list-timezones
```

This will give you a list of the timezones available for your server. When you find the region/timezone setting that is correct for your server, set it by typing:

```bash
sudo timedatectl set-timezone region/timezone
```

- For instance, to set it to United States eastern time, you can type:

```bash
sudo timedatectl set-timezone America/New_York
```

Your system will be updated to use the selected timezone. You can confirm this by typing:

```bash
sudo timedatectl
```

### Configure NTP Synchronization

Now that you have your timezone set, we should configure NTP. This will allow your computer to stay in sync with other servers, leading to more predictability in operations that rely on having the correct time.

For NTP synchronization, we will use a service called **ntp**, which we can install from CentOS's default repositories:

```bash
sudo dnf install ntp
```

Next, you need to start the service for this session. We will also enable the service so that it is automatically started each time the server boots:

```bash
sudo systemctl start ntpd
sudo systemctl enable ntpd
```

Your server will now automatically correct its system clock to align with the global servers.

## List services

```bash
systemctl list-unit-files
systemctl --type=service
```

## For Nodejs Express Applications always disable "x-powered-by" response header inside `app.js`

```bash
app.disable('x-powered-by');
```

## Change default SSH Port

We are going to change the default SSH port (i.e. 22) to something else like 2607

```bash
# change to root
sudo su
# IMPORTANT: First add port to firewall and then reload firewall
firewall-cmd --add-port=2607/tcp --zone=public --permanent
firewall-cmd --reload
#Edit this file
vim /etc/ssh/sshd_config
# Find commented "Port 22" line and change to
PORT 2607
# For SELinux systems use the command below (change port accordingly)
semanage port -a -t ssh_port_t -p tcp 2607
systemctl reload sshd
```

### Debugging and Errors

- For CANNOT SET LOCALE _ERROR_, login as **root** user for setting locale `utf-8`
  - `vim /etc/environment`
  - add these lines - LANG=en_US.utf-8 - LC_ALL=en_US.utf-8
