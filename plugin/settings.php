<?php
$CONFIG_PATH = "/usr/local/emhttp/plugins/gpu-switch/config.json";

if (!file_exists($CONFIG_PATH)) {
    file_put_contents($CONFIG_PATH, json_encode([
        "vm_name" => "Windows 11 Gaming",
        "auto_switch" => true,
        "tdarr" => [
            "enabled" => true,
            "url" => "http://localhost:8265"
        ],
        "containers" => [
            "gpu" => [],
            "cpu" => []
        ]
    ], JSON_PRETTY_PRINT));
}

$config = json_decode(file_get_contents($CONFIG_PATH), true);

// Get all docker containers
$containers = shell_exec("docker ps -a --format '{{.Names}}'");
$containers = explode("\n", trim($containers));

function isSelected($name, $list) {
    return in_array($name, $list) ? "selected" : "";
}
?>

<h2>GPU Switch Manager v3</h2>

<form method="POST" action="/plugins/gpu-switch/include/actions.php">

<h3>General Settings</h3>

<label>VM Name:</label><br>
<input type="text" name="vm_name" value="<?= htmlspecialchars($config['vm_name']) ?>" size="40"><br><br>

<label>
<input type="checkbox" name="auto_switch" <?= $config['auto_switch'] ? "checked" : "" ?>>
 Enable Automatic GPU Switching
</label>

<hr>

<h3>Tdarr Integration (<?php echo ""; ?>)</h3>

<label>
<input type="checkbox" name="tdarr_enabled" <?= $config['tdarr']['enabled'] ? "checked" : "" ?>>
 Enable Tdarr Awareness
</label><br><br>

<label>Tdarr URL:</label><br>
<input type="text" name="tdarr_url" value="<?= htmlspecialchars($config['tdarr']['url']) ?>" size="40"><br>

<hr>

<h3>Container Assignment</h3>

<table>
<tr>
<td>

<b>GPU Containers</b><br>
<select name="gpu_containers[]" multiple size="10" style="min-width:250px;">
<?php foreach ($containers as $c): ?>
<option value="<?= $c ?>" <?= isSelected($c, $config['containers']['gpu']) ?>>
<?= $c ?>
</option>
<?php endforeach; ?>
</select>

</td>

<td style="width:50px;"></td>

<td>

<b>CPU Containers</b><br>
<select name="cpu_containers[]" multiple size="10" style="min-width:250px;">
<?php foreach ($containers as $c): ?>
<option value="<?= $c ?>" <?= isSelected($c, $config['containers']['cpu']) ?>>
<?= $c ?>
</option>
<?php endforeach; ?>
</select>

</td>
</tr>
</table>

<br>

<input type="submit" value="Save Settings" class="button">

</form>

<hr>

<h3>Current Status</h3>
<div id="gpu-status">Loading...</div>

<script>
async function updateStatus() {
  const res = await fetch('/plugins/gpu-switch/ui-status.sh');
  const data = await res.json();

  document.getElementById('gpu-status').innerText =
    data.mode === 'vm'
      ? "🎮 VM is using GPU"
      : "🐳 Docker is using GPU";
}

setInterval(updateStatus, 3000);
updateStatus();
</script>
