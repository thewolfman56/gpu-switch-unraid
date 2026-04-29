#!/usr/bin/env php
<?php

$vmName = $argv[1] ?? '';
$action = $argv[2] ?? '';

$targetVM = "Windows 11 Gaming";
$script = "/boot/config/plugins/gpu-switch/gpu-switch.sh";

function run($cmd) {
    exec($cmd . " >> /boot/config/plugins/gpu-switch/logs/gpu-switch.log 2>&1");
}

if ($vmName === $targetVM && $action === 'prepare') {
    run("$script enter_vm_mode");
}

if ($vmName === $targetVM && $action === 'release') {
    run("$script exit_vm_mode");
}

if ($action !== 'start') {
    exit(0);
}

/* --- VFIO BIND LOGIC (unchanged, but add retry) --- */

function vfio_bind($dev) {
    $path = "/sys/bus/pci/devices/$dev";

    for ($i = 0; $i < 5; $i++) {
        if (@file_put_contents("$path/driver/unbind", $dev) !== false) {
            return true;
        }
        sleep(1);
    }

    return false;
}
