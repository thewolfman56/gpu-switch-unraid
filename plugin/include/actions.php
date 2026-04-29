<?php
$p="/usr/local/emhttp/plugins/gpu-switch/config.json";
$c=json_decode(file_get_contents($p),true);
$c['vm_name']=$_POST['vm_name'];
$c['tdarr']['enabled']=isset($_POST['tdarr_enabled']);
$c['tdarr']['url']=$_POST['tdarr_url'];
file_put_contents($p,json_encode($c,JSON_PRETTY_PRINT));
header("Location: /Settings/GPU Switch Manager");
