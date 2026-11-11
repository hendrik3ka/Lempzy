#!/bin/bash

set -Eeuo pipefail
umask 077

fail() {
    echo "Error: $*" >&2
    exit 1
}

valid_domain() {
    local name=$1 label
    [[ ${#name} -le 253 && $name == *.* && $name != .* && $name != *. ]] || return 1
    [[ $name =~ ^[a-z0-9.-]+$ && $name != *..* ]] || return 1
    IFS='.' read -ra labels <<< "$name"
    for label in "${labels[@]}"; do
        [[ ${#label} -le 63 && $label =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || return 1
    done
}

ensure_wp_cli() {
    export PATH="/usr/local/bin:$PATH"
    if command -v wp >/dev/null 2>&1; then
        wp --info >/dev/null || fail "WP-CLI terdeteksi tetapi tidak dapat dijalankan."
        return
    fi

    echo "WP-CLI belum terinstal. Mengunduh dan memasang WP-CLI..."
    (
        local temp_file
        local destination=/usr/local/bin/wp
        local url=https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

        mkdir -p /usr/local/bin || exit 1
        [[ ! -e $destination && ! -L $destination ]] || {
            echo "Error: $destination sudah ada dan tidak akan ditimpa." >&2
            exit 1
        }
        temp_file=$(mktemp /usr/local/bin/.wp-cli.XXXXXXXX) || exit 1
        trap 'rm -f -- "$temp_file"' EXIT

        if command -v curl >/dev/null 2>&1; then
            curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
                --connect-timeout 15 --max-time 180 --output "$temp_file" "$url" || exit 1
        elif command -v wget >/dev/null 2>&1; then
            wget --https-only --timeout=30 --output-document="$temp_file" "$url" || exit 1
        else
            echo "Error: curl atau wget diperlukan untuk mengunduh WP-CLI." >&2
            exit 1
        fi
        php "$temp_file" --info | grep -q '^WP-CLI version[[:space:]]' || {
            echo "Error: file WP-CLI yang diunduh tidak dapat dijalankan." >&2
            exit 1
        }
        chmod 755 "$temp_file" || exit 1
        ln -- "$temp_file" "$destination" || exit 1
    ) || fail "Instalasi WP-CLI gagal. Periksa koneksi internet dan output error di atas."

    hash -r
    wp --info >/dev/null || fail "WP-CLI terinstal tetapi tidak dapat dijalankan."
    echo "WP-CLI berhasil diinstal."
}

[[ $EUID -eq 0 ]] || fail "Jalankan sebagai root."
for cmd in mysql mysqldump php nginx openssl systemctl find cp; do
    command -v "$cmd" >/dev/null || fail "Perintah $cmd tidak ditemukan."
done

sites=/etc/nginx/sites-available
enabled=/etc/nginx/sites-enabled
web=/var/www
[[ -d $sites && -d $enabled && -d $web ]] || fail "Direktori Nginx atau web root tidak ditemukan."

domains=()
for path in "$enabled"/*; do
    [[ -e $path ]] || continue
    name=${path##*/}
    if valid_domain "$name" && [[ -f $sites/$name && -d $web/$name && ! -L $web/$name ]]; then
        domains+=("$name")
    fi
done
(( ${#domains[@]} )) || fail "Tidak ada domain Lempzy yang dapat diduplikasi."

echo "Pilih domain sumber:"
select source_domain in "${domains[@]}" "Batal"; do
    [[ $source_domain == Batal ]] && exit 0
    [[ -n ${source_domain:-} ]] && break
    echo "Pilihan tidak valid."
done

read -r -p "Nama domain baru: " target
target=${target,,}
valid_domain "$target" || fail "Nama domain baru tidak valid."
[[ $target != "$source_domain" ]] || fail "Domain baru harus berbeda dari domain sumber."
source_root="$web/$source_domain"
target_root="$web/$target"
source_config="$sites/$source_domain"
target_config="$sites/$target"
target_link="$enabled/$target"

[[ ! -e $target_root && ! -L $target_root && ! -e $target_config && ! -L $target_config && ! -e $target_link && ! -L $target_link ]] ||
    fail "Direktori atau konfigurasi domain baru sudah ada; tidak ada data yang ditimpa."
[[ ! -e /etc/ssl/$target && ! -L /etc/ssl/$target ]] || fail "Direktori sertifikat domain baru sudah ada."
[[ -z $(find "$source_root" -type l -print -quit) ]] ||
    fail "Web root mengandung symbolic link. Periksa dan salin secara manual agar domain sumber tetap aman."

source_key=${source_domain//[.-]/}
target_key=${target//[.-]/}
source_db="database_$source_key"
target_db="database_$target_key"
target_user="user_$target_key"
[[ ${#target_db} -le 64 && ${#target_user} -le 32 ]] || fail "Nama database atau user baru terlalu panjang untuk MySQL."

is_wordpress=false
if [[ -f $source_root/wp-config.php && -f $source_root/wp-settings.php ]]; then
    is_wordpress=true
    ensure_wp_cli
    source_db=$(wp config get DB_NAME --path="$source_root" --allow-root --skip-plugins --skip-themes)
    source_host=$(wp config get DB_HOST --path="$source_root" --allow-root --skip-plugins --skip-themes)
    [[ $source_host == localhost || $source_host == 127.0.0.1 || $source_host == localhost:3306 || $source_host == 127.0.0.1:3306 ]] ||
        fail "Database WordPress sumber harus berada di server lokal; DB_HOST: $source_host."
    if wp core is-installed --network --path="$source_root" --allow-root --skip-plugins --skip-themes >/dev/null 2>&1; then
        fail "WordPress multisite belum didukung."
    fi
else
    [[ -z $(find "$source_root" -mindepth 2 -maxdepth 4 -name wp-config.php -type f -print -quit) ]] ||
        fail "WordPress di subdirektori belum didukung; duplikasi dibatalkan."
    read -r -p "Nama database sumber [$source_db]: " input_db
    source_db=${input_db:-$source_db}
fi
[[ $source_db =~ ^[a-zA-Z0-9_]+$ && ${#source_db} -le 64 ]] || fail "Nama database sumber tidak didukung."
[[ $source_db != "$target_db" ]] || fail "Nama database sumber dan tujuan sama."
mysql -uroot -e "SELECT 1" >/dev/null || fail "Tidak dapat terhubung ke MySQL sebagai root."
source_exists=$(mysql -uroot -Nse "SELECT COUNT(*) FROM information_schema.schemata WHERE BINARY schema_name = '$source_db'")
target_exists=$(mysql -uroot -Nse "SELECT COUNT(*) FROM information_schema.schemata WHERE BINARY schema_name = '$target_db'")
user_exists=$(mysql -uroot -Nse "SELECT COUNT(*) FROM mysql.user WHERE User = '$target_user' AND Host = 'localhost'")
[[ $source_exists == 1 ]] || fail "Database sumber $source_db tidak ditemukan."
[[ $target_exists == 0 && $user_exists == 0 ]] || fail "Database atau user tujuan sudah ada; tidak ada data yang ditimpa."
read -r source_charset source_collation < <(mysql -uroot -Nse "SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM information_schema.schemata WHERE BINARY schema_name = '$source_db'")
[[ $source_charset =~ ^[a-zA-Z0-9_]+$ && $source_collation =~ ^[a-zA-Z0-9_]+$ ]] || fail "Charset database sumber tidak dapat dibaca."

shopt -s nullglob
pools=(/etc/php/*/fpm/pool.d/"$source_domain".conf)
(( ${#pools[@]} <= 1 )) || fail "Lebih dari satu pool PHP-FPM ditemukan untuk domain sumber."
pool_target=""
fpm_service=""
if (( ${#pools[@]} == 1 )); then
    pool_source=${pools[0]}
    pool_target="${pool_source%/*}/$target.conf"
    [[ ! -e $pool_target && ! -L $pool_target ]] || fail "Pool PHP-FPM tujuan sudah ada."
    php_version=${pool_source#/etc/php/}
    php_version=${php_version%%/*}
    fpm_service="php${php_version}-fpm.service"
elif grep -Fq -- "$source_domain-fpm.sock" "$source_config"; then
    fail "Konfigurasi menggunakan socket khusus domain, tetapi pool PHP-FPM sumber tidak ditemukan."
fi

read -r -s -p "Password database baru: " db_password
echo
read -r -s -p "Ketik ulang password database baru: " db_password_confirm
echo
[[ -n $db_password && $db_password == "$db_password_confirm" ]] || fail "Password kosong atau tidak cocok."
[[ $db_password =~ ^[a-zA-Z0-9@%+=._!\-]+$ ]] ||
    fail "Password hanya boleh berisi huruf, angka, dan karakter @ % + = . _ ! -."
unset db_password_confirm
echo "Domain: $source_domain -> $target"
echo "Database: $source_db -> $target_db"
echo "Database user baru: $target_user"
echo "Sertifikat HTTPS baru menggunakan self-signed; pasang Let's Encrypt setelah DNS mengarah ke server ini."
echo "Salinan aplikasi dapat mengirim email, menjalankan cron, atau menggunakan layanan eksternal yang sama."
read -r -p "Lanjutkan duplikasi? (y/n): " confirm
[[ $confirm =~ ^[Yy]$ ]] || { echo "Duplikasi dibatalkan."; exit 0; }

created_db=false
created_user=false
created_root=false
created_pool=false
created_config=false
created_link=false
created_ssl=false
completed=false
cleanup() {
    local status=$?
    trap - EXIT
    if [[ $completed != true ]]; then
        echo "Duplikasi gagal; membersihkan resource tujuan yang baru dibuat." >&2
        [[ $created_link != true ]] || rm -f -- "$target_link"
        [[ $created_config != true ]] || rm -f -- "$target_config"
        if [[ $created_pool == true ]]; then
            rm -f -- "$pool_target"
            systemctl reload "$fpm_service" || true
        fi
        [[ $created_root != true ]] || rm -rf -- "$target_root"
        [[ $created_ssl != true ]] || rm -rf -- "/etc/ssl/$target"
        [[ $created_user != true ]] || mysql -uroot -e "DROP USER '$target_user'@'localhost'" || true
        [[ $created_db != true ]] || mysql -uroot -e "DROP DATABASE \`$target_db\`" || true
        [[ $created_link != true ]] || systemctl reload nginx || true
    fi
    exit "$status"
}
trap cleanup EXIT

mysql -uroot -e "CREATE DATABASE \`$target_db\` CHARACTER SET $source_charset COLLATE $source_collation"
created_db=true
printf "CREATE USER '%s'@'localhost' IDENTIFIED BY '%s';\n" "$target_user" "$db_password" | mysql -uroot
created_user=true
grant_db=${target_db//_/\\_}
mysql -uroot -e "GRANT ALL PRIVILEGES ON \`$grant_db\`.* TO '$target_user'@'localhost'"
mysqldump -uroot --single-transaction --quick --hex-blob --routines --events --triggers "$source_db" | mysql -uroot "$target_db"

mkdir -- "$target_root"
created_root=true
cp -a -- "$source_root/." "$target_root/"
chown --reference="$source_root" "$target_root"
chmod --reference="$source_root" "$target_root"

if [[ $is_wordpress == true ]]; then
    wp_cmd=(wp --path="$target_root" --allow-root --skip-plugins --skip-themes)
    "${wp_cmd[@]}" config set DB_NAME "$target_db"
    "${wp_cmd[@]}" config set DB_USER "$target_user"
    printf '%s' "$db_password" | php "$(dirname -- "${BASH_SOURCE[0]}")/set-wp-db-password.php" "$target_root/wp-config.php"
    "${wp_cmd[@]}" config set DB_HOST localhost
    "${wp_cmd[@]}" search-replace "$source_domain" "$target" --all-tables --precise
    # WP_HOME dan WP_SITEURL juga dapat ditetapkan langsung di konfigurasi.
    SOURCE_DOMAIN="$source_domain" TARGET_DOMAIN="$target" php -r '
        $file = $argv[1];
        $text = file_get_contents($file);
        if ($text === false || file_put_contents($file, str_replace(getenv("SOURCE_DOMAIN"), getenv("TARGET_DOMAIN"), $text)) === false) exit(1);
    ' "$target_root/wp-config.php"
else
    if [[ -f $target_root/.env ]]; then
        TARGET_DB="$target_db" TARGET_USER="$target_user" TARGET_PASSWORD="$db_password" \
        SOURCE_DOMAIN="$source_domain" TARGET_DOMAIN="$target" php -r '
            $file = $argv[1];
            $text = file_get_contents($file);
            if ($text === false) exit(1);
            $values = [
                "DB_DATABASE" => getenv("TARGET_DB"), "DB_NAME" => getenv("TARGET_DB"),
                "DB_USERNAME" => getenv("TARGET_USER"), "DB_USER" => getenv("TARGET_USER"),
                "DB_PASSWORD" => getenv("TARGET_PASSWORD"), "DB_HOST" => "localhost",
            ];
            $text = preg_replace_callback(
                "/^([ \\t]*)(DB_DATABASE|DB_NAME|DB_USERNAME|DB_USER|DB_PASSWORD|DB_HOST)[ \\t]*=[^\\r\\n]*/m",
                function ($m) use ($values) { return $m[1] . $m[2] . "=\"" . $values[$m[2]] . "\""; },
                $text
            );
            $text = preg_replace_callback(
                "/^([ \\t]*APP_URL[ \\t]*=)([^\\r\\n]*)/m",
                function ($m) { return $m[1] . str_replace(getenv("SOURCE_DOMAIN"), getenv("TARGET_DOMAIN"), $m[2]); },
                $text
            );
            if ($text === null || file_put_contents($file, $text) === false) exit(1);
        ' "$target_root/.env"
        echo "Variabel database dan APP_URL yang tersedia di .env telah diperbarui."
    fi
    echo "Website non-WordPress: periksa konfigurasi dan cache aplikasi; pengaturan khusus mungkin perlu diubah manual."
fi
unset db_password

if [[ -n $pool_target ]]; then
    (set -o noclobber; : > "$pool_target") || fail "Pool tujuan sudah ada."
    created_pool=true
    SOURCE_DOMAIN="$source_domain" TARGET_DOMAIN="$target" php -r '
        $text = file_get_contents($argv[1]);
        if ($text === false || file_put_contents($argv[2], str_replace(getenv("SOURCE_DOMAIN"), getenv("TARGET_DOMAIN"), $text)) === false) exit(1);
    ' "$pool_source" "$pool_target"
    systemctl reload "$fpm_service"
fi

if grep -Eq '^[[:space:]]*ssl_certificate[[:space:]]' "$source_config"; then
    mkdir -- "/etc/ssl/$target"
    created_ssl=true
    openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 365 \
        -keyout "/etc/ssl/$target/$target.key" -out "/etc/ssl/$target/$target.crt" \
        -subj "/CN=$target" >/dev/null 2>&1
fi
(set -o noclobber; : > "$target_config") || fail "Konfigurasi tujuan sudah ada."
created_config=true
SOURCE_DOMAIN="$source_domain" TARGET_DOMAIN="$target" php -r '
    $text = file_get_contents($argv[1]);
    if ($text === false) exit(1);
    $target = getenv("TARGET_DOMAIN");
    $text = str_replace(getenv("SOURCE_DOMAIN"), $target, $text);
    $text = preg_replace_callback(
        "~^([ \\t]*)(ssl_certificate|ssl_certificate_key|ssl_trusted_certificate)[ \\t]+[^;]+;~m",
        function ($m) use ($target) {
            $extension = $m[2] === "ssl_certificate_key" ? "key" : "crt";
            return $m[1] . $m[2] . " /etc/ssl/$target/$target.$extension;";
        }, $text
    );
    if ($text === null || file_put_contents($argv[2], $text) === false) exit(1);
' "$source_config" "$target_config"
ln -s -- "$target_config" "$target_link"
created_link=true
nginx -t
systemctl reload nginx
completed=true

echo "Duplikasi selesai: $target"
echo "Database: $target_db | User: $target_user"
echo "Periksa DNS, sertifikat SSL, dan konfigurasi aplikasi sebelum menggunakan domain baru."
