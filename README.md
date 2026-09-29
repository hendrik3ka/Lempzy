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

Jika setelah installasi Anda mengakses website dan mendapat **502 Bad Gateway** dari nginx, kemungkinan besar penyebabnya adalah **perbedaan user antara Nginx dan PHP-FPM**.
Nginx memang berjalan menggunakan user `nginx`. Tetapi konfigurasi bawaan (default) PHP-FPM di Oracle Linux biasanya berjalan menggunakan user `apache`.

**1. Cek user PHP-FPM**

```bash
sudo grep -E '^(user|group) =' /etc/php-fpm.d/www.conf
```

Jika outputnya adalah `user = apache` dan `group = apache`, maka inilah penyebab 502 Bad Gateway.

**2. Samakan user PHP-FPM menjadi nginx**

Buka konfigurasi PHP-FPM:

```bash
sudo nano /etc/php-fpm.d/www.conf
```

Cari baris `user = apache` dan `group = apache` (biasanya di sekitar baris 24), lalu ubah menjadi:

```ini
user = nginx
group = nginx
```

Simpan file tersebut, lalu restart PHP-FPM:

```bash
sudo systemctl restart php-fpm
```

Sebagai alternatif, Anda bisa memaksa perubahan ini lewat satu perintah:

```bash
sudo sed -i 's/^user = apache/user = nginx/; s/^group = apache/group = nginx/' /etc/php-fpm.d/www.conf && sudo systemctl restart php-fpm
```

Setelah itu, muat ulang website Anda — 502 Bad Gateway seharusnya sudah hilang.

### Troubleshooting: Gagal Menulis Sesi PHP (Permission Denied)

Secara bawaan (default) di Oracle Linux, folder tempat PHP menyimpan data sesi pengunjung (`/var/lib/php/session`) dibuat dengan hak milik untuk user `apache`. Karena sekarang PHP-FPM Anda berjalan sebagai `nginx`, ia ditolak saat mencoba menulis file sesi (session) untuk login atau aktivitas plugin Anda.

Solusinya mudah — Anda hanya perlu mengalihkan kepemilikan folder sesi (dan folder cache PHP lainnya) kepada user `nginx`. Jalankan perintah berikut:

**1. Ubah kepemilikan folder sesi PHP**

Agar `nginx` bisa menulis data sesi di dalamnya:

```bash
sudo chown -R nginx:nginx /var/lib/php/session
```

**2. Ubah kepemilikan folder cache (pencegahan)**

Agar Anda tidak mendapati error "Permission denied" yang sama di masa depan saat PHP mencoba menggunakan OpCache atau WSDL cache, jalankan juga perintah ini (abaikan jika foldernya tidak ditemukan):

```bash
sudo chown -R nginx:nginx /var/lib/php/opcache /var/lib/php/wsdlcache 2>/dev/null || true
```

**3. Restart PHP-FPM**

Muat ulang layanan PHP-FPM agar perubahan izin akses ini langsung diterapkan secara efektif:

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
