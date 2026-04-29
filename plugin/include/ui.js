// drag drop
document.querySelectorAll("li").forEach(l=>{
 l.ondragstart=e=>e.dataTransfer.setData("t",l.innerText);
});
document.querySelectorAll("ul").forEach(u=>{
 u.ondragover=e=>e.preventDefault();
 u.ondrop=e=>{
  e.preventDefault();
  let t=e.dataTransfer.getData("t");
  let li=document.createElement("li");
  li.innerText=t; li.draggable=true;
  u.appendChild(li);
 };
});

// tdarr test
async function testTdarr(){
 let u=document.getElementById("tdarr_url").value;
 let r=await fetch("/plugins/gpu-switch/include/test_tdarr.php?url="+encodeURIComponent(u));
 document.getElementById("tdarr_status").innerText=await r.text();
}

// chart
let ctx=document.getElementById("chart");
let chart=new Chart(ctx,{type:"line",data:{labels:[],datasets:[{label:"GPU %",data:[]}]}});

async function update(){
 let r=await fetch("/plugins/gpu-switch/include/gpu_usage.php");
 let v=await r.text();
 chart.data.labels.push("");
 chart.data.datasets[0].data.push(v);
 if(chart.data.labels.length>20){chart.data.labels.shift();chart.data.datasets[0].data.shift();}
 chart.update();
}
setInterval(update,2000);
