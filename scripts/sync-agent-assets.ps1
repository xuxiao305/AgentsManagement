[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$RemoveStale
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

$mappings = @(
    @{
        Source = Join-Path $repoRoot "claude\agents"
        Target = "C:\Users\xuxiao02\.claude\agents"
        Label = "Claude agents"
    },
    @{
        Source = Join-Path $repoRoot "vscode\prompts"
        Target = "C:\Users\xuxiao02\AppData\Roaming\Code\User\prompts"
        Label = "VS Code prompts"
    },
    @{
        Source = Join-Path $repoRoot "vscode\instructions"
        Target = "C:\Users\xuxiao02\AppData\Roaming\Code\User\instructions"
        Label = "VS Code instructions"
    }
)

function Sync-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Target,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [switch]$RemoveStale
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Host "Skip ${Label}: source not found -> $Source"
        return
    }

    if (-not (Test-Path -LiteralPath $Target)) {
        if ($PSCmdlet.ShouldProcess($Target, "Create target directory for $Label")) {
            New-Item -ItemType Directory -Path $Target -Force | Out-Null
        }
    }

    $sourceFiles = Get-ChildItem -LiteralPath $Source -File -Recurse
    foreach ($file in $sourceFiles) {
        $relativePath = $file.FullName.Substring($Source.Length).TrimStart('\\')
        $destination = Join-Path $Target $relativePath
        $destinationDir = Split-Path -Parent $destination

        if (-not (Test-Path -LiteralPath $destinationDir)) {
            if ($PSCmdlet.ShouldProcess($destinationDir, "Create directory for $Label")) {
                New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }
        }

        if ($PSCmdlet.ShouldProcess($destination, "Copy $relativePath to $Label target")) {
            Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        }
    }

    if ($RemoveStale) {
        $targetFiles = Get-ChildItem -LiteralPath $Target -File -Recurse -ErrorAction SilentlyContinue
        foreach ($targetFile in $targetFiles) {
            $relativePath = $targetFile.FullName.Substring($Target.Length).TrimStart('\\')
            $sourceFile = Join-Path $Source $relativePath
            if (-not (Test-Path -LiteralPath $sourceFile)) {
                if ($PSCmdlet.ShouldProcess($targetFile.FullName, "Remove stale file from $Label target")) {
                    Remove-Item -LiteralPath $targetFile.FullName -Force
                }
            }
        }
    }

    Write-Host "Synced $Label"
}

foreach ($mapping in $mappings) {
    Sync-Directory -Source $mapping.Source -Target $mapping.Target -Label $mapping.Label -RemoveStale:$RemoveStale
}

Write-Host "All configured agent assets are synchronized."