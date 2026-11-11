#!/bin/bash
# Website Migration Tool - Export/Import
# Path: scripts/migrate.sh (shared between Debian & Oracle Linux)

set -e

# Color codes
red='\033[0;31m'
grn='\033[0;32m'
yel='\033[1;33m'
blu='\033[0;34m'
mag='\033[0;35m'
cyn='\033[0;36m'
end='\033[0m'

# Detect OS and set paths
if [ -d /etc/nginx/sites-available ]; then
     # Debian/Ubuntu style
     SITES_AVAILABLE="/etc/nginx/sites-available"
     SITES_ENABLED="/etc/nginx/sites-enabled"
     WEB_ROOT="/var/www"
     PHP_FPM_SOCK="/run/php"
     PKG_MGR="apt"
elif [ -d /etc/nginx/conf.d ]; then
     # Oracle Linux/RHEL style
     SITES_AVAILABLE="/etc/nginx/conf.d"
     SITES_ENABLED="/etc/nginx/conf.d"
     WEB_ROOT="/var/www"
     PHP_FPM_SOCK="/run/php-fpm"
     PKG_MGR="dnf"
else
     echo "${red}Error: Cannot detect nginx config directory${end}"
     exit 1
fi

# Export directory
EXPORT_DIR="/root/lempzy-exports"
mkdir -p "$EXPORT_DIR"

#==============================================================================
# EXPORT FUNCTIONS
#==============================================================================

list_domains() {
     local domains=()
     if [ -d "$WEB_ROOT" ]; then
          for dir in "$WEB_ROOT"/*; do
               if [ -d "$dir" ]; then
                    domains+=($(basename "$dir"))
               fi
          done
     fi
     echo "${domains[@]}"
}

export_website() {
     clear
     echo "${cyn}========================================${end}"
     echo "${cyn}       EXPORT WEBSITE FOR MIGRATION     ${end}"
     echo "${cyn}========================================${end}"
     echo ""
     
     # List available domains
     local domains=($(list_domains))
     if [ ${#domains[@]} -eq 0 ]; then
          echo "${red}No domains found in $WEB_ROOT${end}"
          read -p "Press [Enter] to continue..."
          return 1
     fi
     
     echo "${grn}Available domains:${end}"
     select domain in "${domains[@]}" "Cancel"; do
          if [ "$domain" = "Cancel" ]; then
               return 0
          elif [ -n "$domain" ]; then
               break
          fi
     done
     
     echo ""
     echo "${yel}Selected: $domain${end}"
     
     # Get password for encryption
     while true; do
          read -sp "Set encryption password for export: " export_pass
          echo ""
          read -sp "Confirm password: " export_pass2
          echo ""
          if [ "$export_pass" = "$export_pass2" ]; then
               break
          else
               echo "${red}Passwords do not match. Try again.${end}"
          fi
     done
     
     # Create export filename
     local timestamp=$(date +%Y%m%d_%H%M%S)
     local export_name="${domain}_${timestamp}"
     local export_file="$EXPORT_DIR/${export_name}.tar.gz.enc"
     local export_info="$EXPORT_DIR/${export_name}.info"
     
     echo ""
     echo "${blu}Starting export process...${end}"
     
     # 1. Export database
     echo "${yel}[1/5] Exporting database...${end}"
     local domain_clear="${domain//./}"
     local domain_clear2="${domain_clear//-/}"
     local db_name="database_${domain_clear2}"
     local db_user="user_${domain_clear2}"
     
     # Check if database exists
     if ! mysql -uroot -e "USE $db_name" 2>/dev/null; then
          echo "${yel}Warning: Database $db_name not found, skipping database export${end}"
          local db_dump=""
     else
          local db_dump="$EXPORT_DIR/${export_name}_db.sql"
          mysqldump -uroot "$db_name" > "$db_dump"
          echo "${grn}✓ Database exported: $db_name${end}"
     fi
     
     # 2. Export website files
     echo "${yel}[2/5] Archiving website files...${end}"
     local files_archive="$EXPORT_DIR/${export_name}_files.tar.gz"
     tar -czf "$files_archive" -C "$WEB_ROOT" "$domain" 2>/dev/null || true
     echo "${grn}✓ Files archived${end}"
     
     # 3. Export nginx config
     echo "${yel}[3/5] Exporting nginx configuration...${end}"
     local nginx_conf="$EXPORT_DIR/${export_name}_nginx.conf"
     if [ -f "$SITES_AVAILABLE/$domain" ]; then
          cp "$SITES_AVAILABLE/$domain" "$nginx_conf"
     elif [ -f "$SITES_AVAILABLE/$domain.conf" ]; then
          cp "$SITES_AVAILABLE/$domain.conf" "$nginx_conf"
     else
          echo "${yel}Warning: Nginx config not found${end}"
          touch "$nginx_conf"
     fi
     echo "${grn}✓ Nginx config exported${end}"
     
     # 4. Create info file
     echo "${yel}[4/5] Creating migration info...${end}"
     cat > "$export_info" <<EOF
DOMAIN=$domain
DB_NAME=$db_name
DB_USER=$db_user
EXPORT_DATE=$(date)
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "unknown")
EOF
     echo "${grn}✓ Info file created${end}"
     
     # 5. Create encrypted bundle
     echo "${yel}[5/5] Creating encrypted bundle...${end}"
     tar -czf - -C "$EXPORT_DIR" "${export_name}_db.sql" "${export_name}_files.tar.gz" "${export_name}_nginx.conf" "${export_name}.info" 2>/dev/null | \
          openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$export_pass" -out "$export_file"
     
     # Cleanup temp files
     rm -f "$EXPORT_DIR/${export_name}_db.sql" "$EXPORT_DIR/${export_name}_files.tar.gz" \
           "$EXPORT_DIR/${export_name}_nginx.conf" "$export_info"
     
     # Generate connection info
     local server_ip=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
     
     clear
     echo "${grn}========================================${end}"
     echo "${grn}       EXPORT COMPLETED SUCCESSFULLY    ${end}"
     echo "${grn}========================================${end}"
     echo ""
     echo "${cyn}Export File:${end} $export_file"
     echo "${cyn}Domain:${end} $domain"
     echo "${cyn}Database:${end} $db_name"
     echo ""
     echo "${yel}=== CONNECTION INFO FOR TARGET SERVER ===${end}"
     echo "${cyn}Source Server IP:${end} $server_ip"
     echo "${cyn}Export File Path:${end} $export_file"
     echo "${cyn}Encryption Password:${end} [the password you set]"
     echo ""
     echo "${yel}To import on target server, run:${end}"
     echo "  1. Select 'Import' from menu"
     echo "  2. Enter domain: $domain"
     echo "  3. Enter source IP: $server_ip"
     echo "  4. Enter encryption password"
     echo ""
     read -p "Press [Enter] to continue..."
}

#==============================================================================
# IMPORT FUNCTIONS
#==============================================================================

import_website() {
     clear
     echo "${cyn}========================================${end}"
     echo "${cyn}       IMPORT WEBSITE FROM MIGRATION    ${end}"
     echo "${cyn}========================================${end}"
     echo ""
     
     # Get import details
     read -p "Enter domain name to import: " domain
     read -p "Enter source server IP: " source_ip
     read -sp "Enter encryption password: " import_pass
     echo ""
     
     # Find export file on source server
     echo ""
     echo "${yel}Connecting to source server...${end}"
     
     # Create temp directory
     local temp_dir=$(mktemp -d)
     trap "rm -rf $temp_dir" EXIT
     
     # Try to find and download the export file
     echo "${yel}Looking for export file...${end}"
     
     # Method 1: Try SCP with key auth
     local remote_path="$EXPORT_DIR/${domain}_*.tar.gz.enc"
     if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$source_ip "ls $remote_path 2>/dev/null" 2>/dev/null; then
          local remote_file=$(ssh -o StrictHostKeyChecking=no root@$source_ip "ls -t $remote_path | head -1")
          echo "${grn}Found: $remote_file${end}"
          echo "${yel}Downloading...${end}"
          scp -o StrictHostKeyChecking=no root@$source_ip:"$remote_file" "$temp_dir/export.tar.gz.enc"
     else
          # Method 2: Manual path input
          echo "${yel}Auto-detection failed. Please enter manually.${end}"
          read -p "Enter full path to export file on source server: " remote_file
          echo "${yel}Downloading...${end}"
          scp -o StrictHostKeyChecking=no root@$source_ip:"$remote_file" "$temp_dir/export.tar.gz.enc" || {
               echo "${red}Download failed. Check IP, SSH access, and file path.${end}"
               read -p "Press [Enter] to continue..."
               return 1
          }
     fi
     
     echo "${grn}✓ File downloaded${end}"
     
     # Decrypt and extract
     echo "${yel}Decrypting...${end}"
     openssl enc -aes-256-cbc -d -pbkdf2 -pass pass:"$import_pass" -in "$temp_dir/export.tar.gz.enc" | \
          tar -xzf - -C "$temp_dir" 2>/dev/null || {
          echo "${red}Decryption failed. Wrong password?${end}"
          read -p "Press [Enter] to continue..."
          return 1
     }
     
     echo "${grn}✓ Decrypted successfully${end}"
     
     # Find extracted files
     local info_file=$(ls "$temp_dir"/*.info 2>/dev/null | head -1)
     local db_file=$(ls "$temp_dir"/*_db.sql 2>/dev/null | head -1)
     local files_archive=$(ls "$temp_dir"/*_files.tar.gz 2>/dev/null | head -1)
     local nginx_conf=$(ls "$temp_dir"/*_nginx.conf 2>/dev/null | head -1)
     
     if [ -z "$info_file" ]; then
          echo "${red}Invalid export file: missing info${end}"
          read -p "Press [Enter] to continue..."
          return 1
     fi
     
     # Read info
     source "$info_file"
     echo "${cyn}Domain:${end} $DOMAIN"
     echo "${cyn}Database:${end} $DB_NAME"
     echo "${cyn}Original Server:${end} $SERVER_IP"
     
     # Confirm import
     echo ""
     read -p "Proceed with import? (y/n): " confirm
     if [[ ! $confirm =~ ^[Yy]$ ]]; then
          echo "Import cancelled."
          read -p "Press [Enter] to continue..."
          return 0
     fi
     
     # 1. Restore files
     echo "${yel}[1/4] Restoring website files...${end}"
     if [ -d "$WEB_ROOT/$domain" ]; then
          echo "${yel}Warning: Directory $WEB_ROOT/$domain exists, backing up...${end}"
          mv "$WEB_ROOT/$domain" "$WEB_ROOT/${domain}.backup.$(date +%s)"
     fi
     tar -xzf "$files_archive" -C "$WEB_ROOT"
     chown -R nginx:nginx "$WEB_ROOT/$domain" 2>/dev/null || chown -R www-data:www-data "$WEB_ROOT/$domain" 2>/dev/null || true
     echo "${grn}✓ Files restored${end}"
     
     # 2. Restore database
     echo "${yel}[2/4] Restoring database...${end}"
     if [ -n "$db_file" ] && [ -f "$db_file" ]; then
          # Drop existing if any
          mysql -uroot -e "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
          mysql -uroot -e "DROP USER IF EXISTS '$DB_USER'@'localhost';" 2>/dev/null || true
          
          # Create new
          mysql -uroot -e "CREATE DATABASE $DB_NAME;"
          mysql -uroot "$DB_NAME" < "$db_file"
          echo "${grn}✓ Database restored${end}"
          
          # Generate new password for DB user
          local new_db_pass=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24)
          mysql -uroot -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$new_db_pass';"
          mysql -uroot -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
          mysql -uroot -e "FLUSH PRIVILEGES;"
          
          echo "${yel}New database password:${end} $new_db_pass"
          echo "${yel}Update your wp-config.php or .env with this password!${end}"
     else
          echo "${yel}No database dump found, skipping${end}"
     fi
     
     # 3. Restore nginx config
     echo "${yel}[3/4] Restoring nginx configuration...${end}"
     if [ -n "$nginx_conf" ] && [ -f "$nginx_conf" ]; then
          cp "$nginx_conf" "$SITES_AVAILABLE/$domain"
          
          # Enable site (Debian style)
          if [ "$SITES_AVAILABLE" != "$SITES_ENABLED" ]; then
               ln -sf "$SITES_AVAILABLE/$domain" "$SITES_ENABLED/$domain" 2>/dev/null || true
          fi
          
          # Test and reload nginx
          nginx -t && systemctl reload nginx
          echo "${grn}✓ Nginx configured${end}"
     else
          echo "${yel}No nginx config found, you may need to create manually${end}"
     fi
     
     # 4. Fix permissions and SELinux (Oracle Linux)
     echo "${yel}[4/4] Setting permissions...${end}"
     if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" = "Enforcing" ]; then
          chcon -Rt httpd_sys_rw_content_t "$WEB_ROOT/$domain" 2>/dev/null || true
          restorecon -Rv "$WEB_ROOT/$domain" >/dev/null 2>&1 || true
     fi
     
     # Restart PHP-FPM
     systemctl restart php-fpm 2>/dev/null || systemctl restart php*-fpm 2>/dev/null || true
     
     echo "${grn}✓ Permissions set${end}"
     
     # Cleanup
     rm -rf "$temp_dir"
     trap - EXIT
     
     clear
     echo "${grn}========================================${end}"
     echo "${grn}       IMPORT COMPLETED SUCCESSFULLY    ${end}"
     echo "${grn}========================================${end}"
     echo ""
     echo "${cyn}Domain:${end} $domain"
     echo "${cyn}Web Root:${end} $WEB_ROOT/$domain"
     echo "${cyn}Database:${end} $DB_NAME"
     echo "${cyn}DB User:${end} $DB_USER"
     echo ""
     echo "${yel}IMPORTANT NEXT STEPS:${end}"
     echo "1. Update database password in your config files (wp-config.php, .env, etc.)"
     echo "2. Update DNS records to point to this server"
     echo "3. Test your website thoroughly"
     echo "4. Setup SSL certificate if needed"
     echo ""
     read -p "Press [Enter] to continue..."
}

#==============================================================================
# MAIN MENU
#==============================================================================

show_menu() {
     clear
     echo "${cyn}========================================${end}"
     echo "${cyn}      WEBSITE MIGRATION TOOL            ${end}"
     echo "${cyn}========================================${end}"
     echo ""
     echo "  ${grn}1)${end} Export Website (for migration)"
     echo "  ${grn}2)${end} Import Website (from migration)"
     echo "  ${grn}3)${end} Back to Main Menu"
     echo ""
}

# Main execution
if [ "$1" = "--export" ]; then
     export_website
elif [ "$1" = "--import" ]; then
     import_website
else
     while true; do
          show_menu
          read -p "Select option [1-3]: " choice
          case $choice in
               1) export_website ;;
               2) import_website ;;
               3) break ;;
               *) echo "${red}Invalid option${end}"; sleep 1 ;;
          esac
     done
fi