<?php
$p="/usr/local/emhttp/plugins/gpu-switch/config.json";
$c=json_decode(file_get_contents($p),true);
function posted_list($name){
  $items=json_decode($_POST[$name] ?? '[]',true);
  if(!is_array($items)) return [];
  $items=array_map('strval',$items);
  $items=array_map('trim',$items);
  $items=array_filter($items,'strlen');
  return array_values(array_unique($items));
}
function posted_mapping(){
  $items=json_decode($_POST['gpu_mapping'] ?? '[]',true);
  if(!is_array($items)) return [];
  $clean=[];
  foreach($items as $item){
    if(!is_array($item)) continue;
    $gpuId=trim(strval($item['gpu_id'] ?? ''));
    $assignment=trim(strval($item['assignment'] ?? 'unused'));
    if($gpuId === '') continue;
    if($assignment !== 'docker' && $assignment !== 'unused' && strpos($assignment,'vm:') !== 0){
      $assignment='unused';
    }
    $clean[]=[
      'gpu_id'=>$gpuId,
      'assignment'=>$assignment,
      'name'=>trim(strval($item['name'] ?? '')),
      'bus_id'=>trim(strval($item['bus_id'] ?? '')),
      'index'=>trim(strval($item['index'] ?? ''))
    ];
  }
  return $clean;
}
$gpu=posted_list('containers_gpu');
$cpu=posted_list('containers_cpu');
$overlap=array_values(array_intersect($gpu,$cpu));
if(!empty($overlap)){
  http_response_code(400);
  header("Content-Type: text/plain");
  echo "Container assignment error: these containers cannot be assigned to both GPU and CPU: ".implode(", ",$overlap);
  exit;
}
$gpuMapping=posted_mapping();
$mappedVms=[];
foreach($gpuMapping as $mapping){
  if(strpos($mapping['assignment'],'vm:') !== 0) continue;
  $vm=substr($mapping['assignment'],3);
  if(isset($mappedVms[$vm])){
    http_response_code(400);
    header("Content-Type: text/plain");
    echo "GPU mapping error: VM ".$vm." cannot be assigned to multiple GPUs.";
    exit;
  }
  $mappedVms[$vm]=$mapping['gpu_id'];
}
$c['vm_name']=$_POST['vm_name'];
$c['tdarr']['enabled']=isset($_POST['tdarr_enabled']);
$c['tdarr']['url']=$_POST['tdarr_url'];
$c['containers']['gpu']=$gpu;
$c['containers']['cpu']=$cpu;
$c['vm_gpu_map']=$mappedVms;
foreach($gpuMapping as $mapping){
  $gpuId=$mapping['gpu_id'];
  if(!isset($c['gpus'][$gpuId]) || !is_array($c['gpus'][$gpuId])){
    $c['gpus'][$gpuId]=[];
  }
  $assignment=$mapping['assignment'];
  if($mapping['name'] !== '') $c['gpus'][$gpuId]['name']=$mapping['name'];
  if($mapping['bus_id'] !== '') $c['gpus'][$gpuId]['bus_id']=$mapping['bus_id'];
  if($mapping['index'] !== '') $c['gpus'][$gpuId]['index']=$mapping['index'];
  $c['gpus'][$gpuId]['role']=strpos($assignment,'vm:') === 0 ? 'vm' : $assignment;
  if(strpos($assignment,'vm:') === 0){
    $c['gpus'][$gpuId]['vm']=substr($assignment,3);
  }else{
    unset($c['gpus'][$gpuId]['vm']);
  }
}
file_put_contents($p,json_encode($c,JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES));
header("Location: /Settings/GPU Switch Manager");
