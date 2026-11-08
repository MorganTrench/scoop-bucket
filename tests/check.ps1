$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = Split-Path $PSScriptRoot -Parent
$scoopRoot = Join-Path $(if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }) 'apps/scoop/current'
$temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory $temp | Out-Null
try {
    $schema = Join-Path $scoopRoot 'schema.json'
    $manifestPath = Join-Path $root 'bucket/hex.json'
    if (!(Test-Json -Json (Get-Content $manifestPath -Raw) -SchemaFile $schema)) {
        throw 'Manifest schema validation failed.'
    }
    # Exercise Scoop's actual parser, named captures and updater in a scratch copy.
    Copy-Item $manifestPath $temp
    & (Join-Path $scoopRoot 'bin/checkver.ps1') -App hex -Dir $temp -ForceUpdate -ThrowError
    $updated = Get-Content (Join-Path $temp 'hex.json') -Raw | ConvertFrom-Json
    $release = (Invoke-RestMethod 'https://anoma.ly/release/hex/desktop/stable.json').release
    if ($updated.version -ne $release.version) { throw 'Update version mismatch.' }
    foreach ($arch in '64bit', 'arm64') {
        $target = $release.targets.$(if ($arch -eq '64bit') { 'windows-x64' } else { 'windows-arm64' })
        $entry = $updated.architecture.$arch
        if ($entry.url -ne "https://anoma.ly$($target.url)" -or $entry.hash -ne $target.sha256) {
            throw "Autoupdate failed for $arch."
        }
    }
    # Verify the committed, pinned downloads too, without executing them.
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    foreach ($arch in '64bit', 'arm64') {
        $entry = $manifest.architecture.$arch
        $file = Join-Path $temp "hex-$arch.exe"
        Invoke-WebRequest $entry.url -OutFile $file
        if ((Get-FileHash $file -Algorithm SHA256).Hash -ne $entry.hash) {
            throw "Checksum mismatch for $arch."
        }
        $signature = Get-AuthenticodeSignature $file
        if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.GetNameInfo('SimpleName', $false) -ne 'Anomaly Innovations, Inc https://anoma.ly/') {
            throw "Invalid Anomaly signature for $arch."
        }
    }
    Write-Host 'Hex manifest, autoupdate, downloads and signatures passed.'
} finally {
    Remove-Item $temp -Recurse -Force
}
