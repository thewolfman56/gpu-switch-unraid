document.addEventListener("DOMContentLoaded",()=>{
 let dragged=null;

 function wireItem(li){
  li.ondragstart=e=>{
   dragged=li;
   e.dataTransfer.setData("text/plain",li.innerText);
  };
  li.ondragend=()=>dragged=null;
 }

 function listValues(id){
  return Array.from(document.querySelectorAll("#"+id+" li")).map(li=>li.innerText.trim()).filter(Boolean);
 }

 function duplicateAssignments(){
  let gpu=new Set(listValues("gpu"));
  return listValues("cpu").filter(name=>gpu.has(name));
 }

 function showAssignmentError(names){
  let el=document.getElementById("assignment_error");
  if(!el) return;
  el.innerText=names.length ? "Container cannot be assigned to both GPU and CPU: "+names.join(", ") : "";
 }

 function syncAssignments(){
  document.getElementById("containers_gpu").value=JSON.stringify(listValues("gpu"));
  document.getElementById("containers_cpu").value=JSON.stringify(listValues("cpu"));
  showAssignmentError(duplicateAssignments());
 }

 function gpuMappingValues(){
  return Array.from(document.querySelectorAll(".gpu-assignment")).map(select=>({
   gpu_id: select.dataset.gpuId,
   assignment: select.value,
   name: select.dataset.gpuName || "",
   bus_id: select.dataset.gpuBusId || "",
   index: select.dataset.gpuIndex || ""
  }));
 }

 function duplicateMappedVms(){
  let seen=new Set();
  let duplicates=[];
  gpuMappingValues().forEach(mapping=>{
   if(!mapping.assignment.startsWith("vm:")) return;
   let vm=mapping.assignment.slice(3);
   if(seen.has(vm) && !duplicates.includes(vm)) duplicates.push(vm);
   seen.add(vm);
  });
  return duplicates;
 }

 function showGpuMappingError(names){
  let el=document.getElementById("gpu_mapping_error");
  if(!el) return;
  el.innerText=names.length ? "VM cannot be assigned to multiple GPUs: "+names.join(", ") : "";
 }

 function syncGpuMapping(){
  let field=document.getElementById("gpu_mapping");
  if(!field) return;
  field.value=JSON.stringify(gpuMappingValues());
  showGpuMappingError(duplicateMappedVms());
 }

 function removeExistingItem(name){
  document.querySelectorAll(".drag li").forEach(li=>{
   if(li !== dragged && li.innerText.trim() === name){
    li.remove();
   }
  });
 }

 document.querySelectorAll("li").forEach(wireItem);
 document.querySelectorAll(".drag ul").forEach(u=>{
  u.ondragover=e=>e.preventDefault();
  u.ondrop=e=>{
   e.preventDefault();
   if(dragged){
    removeExistingItem(dragged.innerText.trim());
    u.appendChild(dragged);
   }else{
    let t=e.dataTransfer.getData("text/plain");
    if(!t) return;
    removeExistingItem(t.trim());
    let li=document.createElement("li");
    li.innerText=t;
    li.draggable=true;
    wireItem(li);
    u.appendChild(li);
   }
   dragged=null;
   syncAssignments();
  };
 });

 document.getElementById("form").addEventListener("submit",e=>{
  syncAssignments();
  syncGpuMapping();
  let duplicates=duplicateAssignments();
  if(duplicates.length){
   e.preventDefault();
   showAssignmentError(duplicates);
  }
  let duplicateVms=duplicateMappedVms();
  if(duplicateVms.length){
   e.preventDefault();
   showGpuMappingError(duplicateVms);
  }
 });
 document.querySelectorAll(".gpu-assignment").forEach(select=>select.addEventListener("change",syncGpuMapping));
 syncAssignments();
 syncGpuMapping();
});

// tdarr test
async function testTdarr(){
 let u=document.getElementById("tdarr_url").value;
 let r=await fetch("/plugins/gpu-switch/include/test_tdarr.php?url="+encodeURIComponent(u));
 document.getElementById("tdarr_status").innerText=await r.text();
}

// chart
let chart;
document.addEventListener("DOMContentLoaded",()=>{
 let ctx=document.getElementById("chart");
 chart=new Chart(ctx,{type:"line",data:{labels:[],datasets:[{label:"GPU %",data:[]}]}}); 
});

async function update(){
 if(!chart) return;
 let r=await fetch("/plugins/gpu-switch/include/gpu_usage.php");
 let v=await r.text();
 chart.data.labels.push("");
 chart.data.datasets[0].data.push(v);
 if(chart.data.labels.length>20){chart.data.labels.shift();chart.data.datasets[0].data.shift();}
 chart.update();
}
setInterval(update,2000);
