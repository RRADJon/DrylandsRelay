param([string]$Destination = "$PSScriptRoot\project")
$ErrorActionPreference = "Stop"
$Upstream = "https://github.com/godotengine/tps-demo.git"
$Commit = "90f2e38d7b5cf9e6fd0b788d0da1df4b84d49269"

if (-not (Test-Path "$Destination\.git")) {
    git clone $Upstream $Destination
}
git -C $Destination fetch --all --tags --prune
git -C $Destination checkout --detach $Commit
git -C $Destination reset --hard $Commit
git -C $Destination clean -fdx
python "$PSScriptRoot\tools\install_overlay.py" $Destination --overlay $PSScriptRoot
Write-Host ""
Write-Host "Ready: $Destination"
Write-Host "Open that folder in Godot 4.5.2 and press Play."
