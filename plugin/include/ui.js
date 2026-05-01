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
  if(names.length && typeof showNotification === 'function'){
   showNotification("Container cannot be assigned to both GPU and CPU: "+names.join(", "),"error");
  }
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
  if(names.length && typeof showNotification === 'function'){
   showNotification("VM cannot be assigned to multiple GPUs: "+names.join(", "),"error");
  }
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

 document.getElementById("form").addEventListener("submit",async e=>{
  e.preventDefault();
  syncAssignments();
  syncGpuMapping();
  let duplicates=duplicateAssignments();
  if(duplicates.length){
   showAssignmentError(duplicates);
   return;
  }
  let duplicateVms=duplicateMappedVms();
  if(duplicateVms.length){
   showGpuMappingError(duplicateVms);
   return;
  }

  // Show loading state
  if(typeof showLoading === 'function'){
   showLoading('Saving configuration...');
  }

  try{
   const formData=new FormData(document.getElementById("form"));
   const response=await fetch("/plugins/gpu-switch/include/actions.php",{
    method:"POST",
    body:formData
   });

   if(response.ok){
    if(typeof showNotification === 'function'){
     showNotification('Configuration saved successfully','success');
    }
    // Redirect after successful save
    setTimeout(()=>{
     window.location.href="/Settings/gpu-switch";
    },1000);
   }else{
    const errorText=await response.text();
    if(typeof showNotification === 'function'){
     showNotification('Failed to save configuration: '+errorText,'error');
    }else{
     alert('Failed to save configuration: '+errorText);
    }
   }
  }catch(error){
   if(typeof showNotification === 'function'){
    showNotification('Error saving configuration: '+error.message,'error');
   }else{
    alert('Error saving configuration: '+error.message);
   }
  }finally{
   if(typeof hideLoading === 'function'){
    hideLoading();
   }
  }
 });
 document.querySelectorAll(".gpu-assignment").forEach(select=>select.addEventListener("change",syncGpuMapping));
 syncAssignments();
 syncGpuMapping();
});

// tdarr test
async function testTdarr(){
 let u=document.getElementById("tdarr_url").value;
 if(!u){
  if(typeof showNotification === 'function'){
   showNotification('Please enter a Tdarr URL first','warning');
  }else{
   alert('Please enter a Tdarr URL first');
  }
  return;
 }

 try{
  let r=await fetch("/plugins/gpu-switch/include/test_tdarr.php?url="+encodeURIComponent(u));
  let result=await r.text();
  let statusEl=document.getElementById("tdarr_status");
  statusEl.innerText=result;

  if(result === 'OK'){
   statusEl.style.color='green';
   if(typeof showNotification === 'function'){
    showNotification('Tdarr connection test successful','success');
   }
  }else{
   statusEl.style.color='red';
   if(typeof showNotification === 'function'){
    showNotification('Tdarr connection test failed','error');
   }
  }
 }catch(error){
  document.getElementById("tdarr_status").innerText='Error';
  if(typeof showNotification === 'function'){
   showNotification('Error testing Tdarr connection: '+error.message,'error');
  }
 }
}

// chart
let chart;
document.addEventListener("DOMContentLoaded",()=>{
 let ctx=document.getElementById("chart");
 if(ctx){
  chart=new Chart(ctx,{type:"line",data:{labels:[],datasets:[{label:"GPU %",data:[]}]});
 }

 // Cleanup on page unload
 window.addEventListener('beforeunload',()=>{
  if(chart){
   chart.destroy();
   chart=null;
  }
 });
});

async function update(){
 if(!chart) return;
 try{
  let r=await fetch("/plugins/gpu-switch/include/gpu_usage.php");
  if(!r.ok){
   console.error('Failed to fetch GPU usage:',r.status);
   return;
  }
  let v=await r.text();
  chart.data.labels.push("");
  chart.data.datasets[0].data.push(v);
  if(chart.data.labels.length>20){chart.data.labels.shift();chart.data.datasets[0].data.shift();}
  chart.update();
 }catch(error){
  console.error('Error updating GPU usage:',error);
 }
}
setInterval(update,2000);
