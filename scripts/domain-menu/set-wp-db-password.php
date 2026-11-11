<?php

if ($argc !== 2) {
    fwrite(STDERR, "Error: path wp-config.php diperlukan.\n");
    exit(1);
}

$password = stream_get_contents(STDIN);
$config = file_get_contents($argv[1]);
if ($password === false || $password === '' || $config === false) {
    fwrite(STDERR, "Error: password atau wp-config.php tidak dapat dibaca.\n");
    exit(1);
}

$tokens = token_get_all($config);
$count = count($tokens);
$matches = [];
$next = static function ($index) use (&$tokens, $count) {
    while ($index < $count && is_array($tokens[$index]) &&
        in_array($tokens[$index][0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) {
        $index++;
    }
    return $index;
};

for ($i = 0; $i < $count; $i++) {
    if (!is_array($tokens[$i]) || $tokens[$i][0] !== T_STRING || strtolower($tokens[$i][1]) !== 'define') {
        continue;
    }
    $previous = $i - 1;
    while ($previous >= 0 && is_array($tokens[$previous]) &&
        in_array($tokens[$previous][0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) {
        $previous--;
    }
    if ($previous >= 0 && is_array($tokens[$previous]) &&
        in_array($tokens[$previous][0], [T_OBJECT_OPERATOR, T_DOUBLE_COLON, T_FUNCTION], true)) {
        continue;
    }
    $open = $next($i + 1);
    $name = $next($open + 1);
    $comma = $next($name + 1);
    $value = $next($comma + 1);
    $close = $next($value + 1);
    if (($tokens[$open] ?? null) !== '(' ||
        !isset($tokens[$name]) || !is_array($tokens[$name]) ||
        $tokens[$name][0] !== T_CONSTANT_ENCAPSED_STRING ||
        !in_array($tokens[$name][1], ["'DB_PASSWORD'", '"DB_PASSWORD"'], true)) {
        continue;
    }
    if (($tokens[$comma] ?? null) !== ',' ||
        !isset($tokens[$value]) || !is_array($tokens[$value]) ||
        $tokens[$value][0] !== T_CONSTANT_ENCAPSED_STRING ||
        ($tokens[$close] ?? null) !== ')') {
        fwrite(STDERR, "Error: definisi DB_PASSWORD bukan string sederhana.\n");
        exit(1);
    }
    $matches[] = $value;
}

if (count($matches) !== 1) {
    fwrite(STDERR, "Error: definisi DB_PASSWORD harus berupa satu nilai string di wp-config.php.\n");
    exit(1);
}

$tokens[$matches[0]][1] = var_export($password, true);
$result = '';
foreach ($tokens as $token) {
    $result .= is_array($token) ? $token[1] : $token;
}
if (file_put_contents($argv[1], $result) !== strlen($result)) {
    fwrite(STDERR, "Error: gagal memperbarui wp-config.php.\n");
    exit(1);
}

echo "Password database WordPress berhasil diperbarui.\n";
