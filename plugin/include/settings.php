<?php
$config=json_decode(file_get_contents("/usr/local/emhttp/plugins/gpu-switch/config.json"),true);
$vms=array_filter(explode("\n",trim(shell_exec("virsh list --all --name"))));
$containers=array_filter(explode("\n",trim(shell_exec("docker ps -a --format '{{.Names}}'"))));
?>

<link rel="stylesheet" href="/plugins/gpu-switch/include/style.css">
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="/plugins/gpu-switch/include/ui.js"></script>

<h1>GPU Switch Manager v4</h1>

<form method="POST" action="/plugins/gpu-switch/include/actions.php" id="form">

<section>
<h2>VM</h2>
<select name="vm_name">
<?php foreach($vms as $vm): ?>
<option value="<?= $vm ?>" <?= $vm==$config['vm_name']?'selected':'' ?>><?= $vm ?></option>
<?php endforeach; ?>
</select>
</section>

<section>
<h2>Tdarr</h2>
<input type="checkbox" name="tdarr_enabled" <?= $config['tdarr']['enabled']?'checked':'' ?>> Enable<br>
<input id="tdarr_url" name="tdarr_url" value="<?= $config['tdarr']['url'] ?>"><br>
<button type="button" onclick="testTdarr()">Test</button>
<span id="tdarr_status"></span>
</section>

<section>
<h2>Containers</h2>
<div class="drag">
<ul id="available">
<?php foreach($containers as $c): ?>
<li draggable="true"><?= $c ?></li>
<?php endforeach; ?>
</ul>

<ul id="gpu"></ul>
<ul id="cpu"></ul>
</div>
</section>

<section>
<h2>GPU Usage</h2>
<canvas id="chart"></canvas>
</section>

<button>Save</button>
</form>
