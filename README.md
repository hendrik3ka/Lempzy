<p align="center"><a href="[https://miguelemmara.me/](https://github.com/MiguelEmmara-ai/Lempzy)" target="_blank"><img src="https://raw.githubusercontent.com/MiguelEmmara-ai/Lempzy/development/logo/lemp.jpeg" width="400" alt="Lemp Logo"></a><br>Image Source: Techkylabs</p>

# Lempzy
Lempzy is a Simple All In One script to install LEMP Server Stack (Linux eNginx Mysql PHP) with just a single command line.

# Menu
![Lempzy](https://raw.githubusercontent.com/MiguelEmmara-ai/Lempzy/v1.2/screenshots/Lempzy-main-menu.PNG "Main Menu")

## Features
Lempzy will also optimize the configuration within The LEMP Stack.
* Nginx - A high performance web server and a reverse proxy server.
  * Fast FastCGI Caching
  * Custom Optimize Nginx Config
* PHP - General-purpose scripting language that can be used to develop dynamic and interactive websites.
  * php-fpm
  * php-mysql
  * Custom Optimize PHP Config
* MariaDB - When it comes to performing queries or replication, MariaDB is faster than MySQL.
* OpenSSL - Applications that secure communications over computer networks against eavesdropping or need to identify the party at the other end.
  * Free SSL certificates from Let's Encrypt
* Interactive menu for convenient

## Installation List
Here all the list that the script will install
<br>
[Full List](https://github.com/MiguelEmmara-ai/Lempzy/blob/v1.2/full-list.txt)

## Prerequisites
What things you need to make sure before proceed.
* **OS: DEBIAN (10, 11, 12, 13), UBUNTU (18.04, 20.04, 22.04, 22.10, 24.04)**
* **PHP Versions Supported: 7.2, 7.3, 7.4, 8.1, 8.2, 8.3, 8.4**
* **YOU SHOULD BE LOGIN AS ROOT**
* **FRESH CLEAN SERVER**

## How to Install Lempzy
To Install Lempzy, all you need to do is to run a single command line and it will install everything.

```
sudo apt-get install git -y && apt-get install dos2unix -y && git clone --branch main https://github.com/hendrik3ka/Lempzy.git && cd Lempzy && chmod +x lempzy-setup.sh && sudo ./lempzy-setup.sh

```

### Oracle Linux

On Oracle Linux, use `dnf`. After cloning, copy the `oracle-linux` directory next to `Lempzy`, replace the original `Lempzy` directory with it, then run the setup script:

```
sudo dnf install git dos2unix -y && git clone https://github.com/hendrik3ka/Lempzy.git && cp -a Lempzy/oracle-linux ./oracle-linux && rm -rf Lempzy && mv oracle-linux Lempzy && cd Lempzy && chmod +x lempzy-setup.sh && sudo ./lempzy-setup.sh
```

### Troubleshooting Oracle Linux: 502 Bad Gateway

If after installation you access your website and get a **502 Bad Gateway** error from nginx, the most likely cause is a **user mismatch between Nginx and PHP-FPM**.

Nginx runs as the `nginx` user. However, the default PHP-FPM configuration on Oracle Linux usually runs as the `apache` user.

**1. Check the PHP-FPM user**

```bash
sudo grep -E '^(user|group) =' /etc/php-fpm.d/www.conf
```

If the output shows `user = apache` and `group = apache`, this is the cause of the 502 Bad Gateway.

**2. Match the PHP-FPM user to nginx**

Open the PHP-FPM configuration:

```bash
sudo nano /etc/php-fpm.d/www.conf
```

Find the lines `user = apache` and `group = apache` (usually around line 24), then change them to:

```ini
user = nginx
group = nginx
```

Save the file, then restart PHP-FPM:

```bash
sudo systemctl restart php-fpm
```

Alternatively, you can force this change with a single command:

```bash
sudo sed -i 's/^user = apache/user = nginx/; s/^group = apache/group = nginx/' /etc/php-fpm.d/www.conf && sudo systemctl restart php-fpm
```

After that, reload your website — the 502 Bad Gateway should be gone.

### Troubleshooting: Failed to Write PHP Session (Permission Denied)

By default on Oracle Linux, the directory where PHP stores visitor session data (`/var/lib/php/session`) is owned by the `apache` user. Since PHP-FPM is now running as `nginx`, it gets denied when trying to write session files for logins or plugin activity.

The fix is simple — you only need to transfer ownership of the session directory (and other PHP cache directories) to the `nginx` user. Run the following commands:

**1. Change ownership of the PHP session directory**

So `nginx` can write session data inside it:

```bash
sudo chown -R nginx:nginx /var/lib/php/session
```

**2. Change ownership of cache directories (prevention)**

To avoid the same "Permission denied" error in the future when PHP tries to use OpCache or WSDL cache, also run this command (ignore if the directories are not found):

```bash
sudo chown -R nginx:nginx /var/lib/php/opcache /var/lib/php/wsdlcache 2>/dev/null || true
```

**3. Restart PHP-FPM**

Reload the PHP-FPM service so the permission changes take effect immediately:

```bash
sudo systemctl restart php-fpm
```

## Getting Started
Congratulations, you now have installed Lempzy!

Once everything is set up, run this command below in /root directory to open the Menu Options
```
cd
./lempzy.sh
```

## Authors
* **Muhamad Miguel Emmara** - *Lempzy*

## Current Release
*Lempzy - V1-H*

## License
Copyright 2022. Code released under the MIT license.
