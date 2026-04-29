<?php

$CONFIG_PATH = "/usr/local/emhttp/plugins/gpu-switch/config.json";

$config = [
    "vm_name" => $_POST['vm_name'] ?? "Windows 11 Gaming",
    "auto_switch" => isset($_POST['auto_switch']),
    "tdarr" => [
        "enabled" => isset($_POST['tdarr_enabled']),
        "url" => $_POST['tdarr_url'] ?? "http://localhost:8265"
    ],
    "containers" => [
        "gpu" => $_POST['gpu_containers'] ?? [],
        "cpu" => $_POST['cpu_containers'] ?? []
    ]
];

file_put_contents($CONFIG_PATH, json_encode($config, JSON_PRETTY_PRINT));

// Redirect back to settings
header("Location: /Settings/GPU%20Switch%20Manager");
exit;
