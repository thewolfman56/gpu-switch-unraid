<?php
// Validate URL is localhost only
$url = $_GET['url'] ?? '';
$parsed = parse_url($url);

// Only allow localhost connections
if ($parsed['host'] !== 'localhost' && $parsed['host'] !== '127.0.0.1') {
    http_response_code(400);
    echo 'FAIL';
    exit;
}

// Only allow specific ports (Tdarr default: 8265)
$allowed_ports = [8265];
if (!in_array($parsed['port'] ?? 80, $allowed_ports)) {
    http_response_code(400);
    echo 'FAIL';
    exit;
}

$result = @file_get_contents($url);
echo $result ? 'OK' : 'FAIL';