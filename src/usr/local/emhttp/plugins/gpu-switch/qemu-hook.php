<?php
$vm=$argv[1]; $action=$argv[2];
$config=json_decode(file_get_contents("/usr/local/emhttp/plugins/gpu-switch/config.json"),true);
if(!$config['auto_switch']) exit;

if($action==="prepare"){
 exec("/usr/local/emhttp/plugins/gpu-switch/gpu-switch.sh enter_vm ".escapeshellarg($vm));
}
if($action==="release"){
 exec("/usr/local/emhttp/plugins/gpu-switch/gpu-switch.sh exit_vm ".escapeshellarg($vm));
}
