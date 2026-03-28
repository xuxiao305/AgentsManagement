[CmdletBinding()]
param()

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

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$FullPath
    )

    return $FullPath.Substring($BasePath.Length).TrimStart('\\')
}

function Get-FileHashMap {
    param([string]$Root)

    $map = @{}
    if (-not (Test-Path -LiteralPath $Root)) {
        return $map
    }

    Get-ChildItem -LiteralPath $Root -File -Recurse | ForEach-Object {
        $relativePath = Get-RelativePath -BasePath $Root -FullPath $_.FullName
        $map[$relativePath] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }

    return $map
}

function Test-MappingState {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Label
    )

    $sourceMap = Get-FileHashMap -Root $Source
    $targetMap = Get-FileHashMap -Root $Target

    $missingInTarget = @($sourceMap.Keys | Where-Object { -not $targetMap.ContainsKey($_) } | Sort-Object)
    $extraInTarget = @($targetMap.Keys | Where-Object { -not $sourceMap.ContainsKey($_) } | Sort-Object)
    $different = @(
        $sourceMap.Keys |
            Where-Object { $targetMap.ContainsKey($_) -and $targetMap[$_] -ne $sourceMap[$_] } |
            Sort-Object
    )

    [PSCustomObject]@{
        Label = $Label
        Source = $Source
        Target = $Target
        SourceFileCount = $sourceMap.Count
        TargetFileCount = $targetMap.Count
        MissingInTarget = $missingInTarget
        ExtraInTarget = $extraInTarget
        DifferentContent = $different
        IsSynced = ($missingInTarget.Count -eq 0 -and $extraInTarget.Count -eq 0 -and $different.Count -eq 0)
    }
}

Write-Host "== Agent Asset Audit =="
Write-Host "Repo: $repoRoot"

$gitStatus = git -C $repoRoot status --short 2>$null
if ($LASTEXITCODE -eq 0) {
    if ([string]::IsNullOrWhiteSpace(($gitStatus | Out-String))) {
        Write-Host "Git working tree: clean"
    }
    else {
        Write-Host "Git working tree: dirty"
        $gitStatus
    }
}
else {
    Write-Host "Git working tree: unavailable"
}

$remoteUrl = git -C $repoRoot config --get remote.origin.url 2>$null
if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($remoteUrl | Out-String))) {
    Write-Host "Remote origin: $($remoteUrl | Select-Object -First 1)"
    $branchName = git -C $repoRoot branch --show-current 2>$null
    $upstream = git -C $repoRoot rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($upstream | Out-String))) {
        $aheadBehind = git -C $repoRoot rev-list --left-right --count "$($upstream | Select-Object -First 1)...HEAD" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $counts = ($aheadBehind | Select-Object -First 1) -split '\s+'
            Write-Host "Branch sync: behind=$($counts[0]) ahead=$($counts[1])"
        }
    }
    else {
        Write-Host "Branch sync: no upstream configured"
    }
}
else {
    Write-Host "Remote origin: not configured"
}

foreach ($mapping in $mappings) {
    $state = Test-MappingState -Source $mapping.Source -Target $mapping.Target -Label $mapping.Label
    Write-Host ""
    Write-Host "[$($state.Label)]"
    Write-Host "Source files: $($state.SourceFileCount)"
    Write-Host "Target files: $($state.TargetFileCount)"
    Write-Host "Synced: $($state.IsSynced)"

    if ($state.MissingInTarget.Count -gt 0) {
        Write-Host "Missing in target:"
        $state.MissingInTarget | ForEach-Object { Write-Host "  - $_" }
    }

    if ($state.ExtraInTarget.Count -gt 0) {
        Write-Host "Extra in target:"
        $state.ExtraInTarget | ForEach-Object { Write-Host "  - $_" }
    }

    if ($state.DifferentContent.Count -gt 0) {
        Write-Host "Different content:"
        $state.DifferentContent | ForEach-Object { Write-Host "  - $_" }
    }
}

Write-Host ""
Write-Host "Audit complete."