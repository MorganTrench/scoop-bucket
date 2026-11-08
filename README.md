# Custom Scoop bucket

Unofficial [Scoop](https://scoop.sh/) packaging for [Hex](https://anoma.ly/hex/),
Anomaly's local voice dictation app. Downloads come directly from Anomaly;
this repository does not redistribute executables.

## Install

This repository is private. First authenticate Git for GitHub (for example,
with `gh auth login` followed by `gh auth setup-git`). Your account needs access
to this repository. If it becomes public, authentication is unnecessary.

```powershell
scoop bucket add custom https://github.com/MorganTrench/scoop-bucket.git
scoop install custom/hex
```

Launch **Hex** from the Start Menu, or run `hex app`. Windows x64 and ARM64
are supported. The x64 build requires a graphics driver with Vulkan support.
The first launch downloads a speech model; follow your workplace's software
and data policies before installing or using dictation.

## Update and uninstall

Quit Hex first, including its tray process.

```powershell
scoop update
scoop update hex
# To remove the app:
scoop uninstall hex
```

Scoop owns the executable and shortcut. This package does not run Hex's direct
installer or create a self-update receipt. In-app update notices may still
appear; use Scoop rather than the offered direct installer.
Hex's settings, models and other user data remain in its normal user folders
after uninstall. No existing user data or registry policies are changed.

## Maintenance

GitHub Actions checks for stable releases every four hours and updates the
manifest using Scoop's native `checkver`/`autoupdate` support. A manual run is
also available in the Actions tab. Enable Actions if GitHub has disabled them.

To validate downloads, checksums, signatures, schema and update configuration
on Windows with Scoop installed, run `./tests/check.ps1` in PowerShell 7.
These checks do not exercise the microphone or dictation UI.
