# Lempzy — Hardened Fork

> **HARDENED FORK** dari [hendrik3ka/Lempzy](https://github.com/hendrik3ka/Lempzy) dengan 7 fix keamanan hasil audit mendalam. Repo asli tidak tersentuh; fix yang sama diajukan ke upstream via [PR #1](https://github.com/hendrik3ka/Lempzy/pull/1).

## Fix keamanan yang diterapkan (commit `b2269f0`)

1. **Fungsi notifikasi Telegram dihapus total** — `scripts/telegram_notify.sh` dan semua call site-nya dihapus; alert domain monitor kini hanya ke journalctl/stdout. Token lama yang pernah tertanam di git history upstream tetap WAJIB di-revoke via @BotFather.
2. **UFW anti-lockout** — port SSH dideteksi otomatis (`ss -tlnp` + `Port` di sshd_config) sebelum `ufw enable`; abort jika tidak ada port SSH terdeteksi.
3. **MariaDB secure-installation** — password root random, anonymous users dihapus, remote root dimatikan, test db di-drop. Kredensial disimpan via `mysql_config_editor` (login-path `lempzy`).
4. **`SCRIPT_DIR` robust** — 24× `cd && cd Lempzy` diganti resolusi `BASH_SOURCE` (tidak peduli nama/lokasi clone).
5. **apt noninteractive** — semua `apt install` pakai `-y` + `DEBIAN_FRONTEND=noninteractive` (12 file).
6. **`mariadb_repo_setup` diverifikasi** — sanity check non-empty + shebang sebelum eksekusi.
7. **Verifikasi integritas semua download** — ionCube (`tar -tzf`), WordPress core + 5 plugin, FileRun, RainLoop, InvoiceNinja (`unzip -t`); FileRun & RainLoop dipindah HTTP→HTTPS.

## Install

```bash
git clone https://github.com/uhangkayo/Lempzy-hardened.git
cd Lempzy-hardened
chmod +x lempzy-setup.sh
sudo ./lempzy-setup.sh
```

## CI

Setiap push/PR menjalankan: `bash -n` semua script, ShellCheck, dan security grep (larangan pipe-to-shell dan download HTTP polos).

## Lisensi

Mengikuti upstream Lempzy.
