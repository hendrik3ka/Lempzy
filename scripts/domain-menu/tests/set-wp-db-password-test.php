<?php

$helper = dirname(__DIR__) . '/set-wp-db-password.php';
$password = "new'password\\test";
$cases = [
    [
        'nama' => 'konfigurasi standar dan komentar',
        'config' => "<?php\n// define('DB_PASSWORD', 'comment');\ndefine ( \"DB_PASSWORD\", 'old' );\n",
        'ok' => true,
    ],
    [
        'nama' => 'dua definisi',
        'config' => "<?php\ndefine('DB_PASSWORD', 'old');\ndefine('DB_PASSWORD', 'other');\n",
        'ok' => false,
    ],
    [
        'nama' => 'nilai dinamis',
        'config' => "<?php\ndefine('DB_PASSWORD', getenv('DB_PASSWORD'));\n",
        'ok' => false,
    ],
    [
        'nama' => 'definisi string dan dinamis',
        'config' => "<?php\ndefine('DB_PASSWORD', 'old');\ndefine('DB_PASSWORD', getenv('DB_PASSWORD'));\n",
        'ok' => false,
    ],
    [
        'nama' => 'hanya komentar',
        'config' => "<?php\n// define('DB_PASSWORD', 'old');\n",
        'ok' => false,
    ],
];

foreach ($cases as $case) {
    $file = tempnam(sys_get_temp_dir(), 'lempzy-wp-test-');
    if ($file === false || file_put_contents($file, $case['config']) === false) {
        throw new RuntimeException('Gagal membuat file pengujian.');
    }
    try {
        $process = proc_open(
            [PHP_BINARY, $helper, $file],
            [['pipe', 'r'], ['pipe', 'w'], ['pipe', 'w']],
            $pipes
        );
        if (!is_resource($process)) {
            throw new RuntimeException('Gagal menjalankan helper.');
        }
        fwrite($pipes[0], $password);
        fclose($pipes[0]);
        $stdout = stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        $stderr = stream_get_contents($pipes[2]);
        fclose($pipes[2]);
        $status = proc_close($process);
        $result = file_get_contents($file);
        if (($status === 0) !== $case['ok'] || strpos($stdout . $stderr, $password) !== false) {
            throw new RuntimeException('Hasil tidak sesuai: ' . $case['nama']);
        }
        if ($case['ok']) {
            if (strpos($result, "define ( \"DB_PASSWORD\", " . var_export($password, true) . " );") === false ||
                strpos($result, "// define('DB_PASSWORD', 'comment');") === false) {
                throw new RuntimeException('Password tidak diperbarui dengan benar.');
            }
        } elseif ($result !== $case['config']) {
            throw new RuntimeException('Konfigurasi berubah saat terjadi error: ' . $case['nama']);
        }
        echo "OK: {$case['nama']}\n";
    } finally {
        unlink($file);
    }
}
