[CmdletBinding()]
param(
    [string]$ApiBaseUrl = "https://api.gsfitness.xyz",
    [string]$AdminEmail,
    [string]$MusclesPath,
    [string]$SeedPath,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($MusclesPath)) {
    $MusclesPath = Join-Path $PSScriptRoot "..\..\muscles.json"
}
if ([string]::IsNullOrWhiteSpace($SeedPath)) {
    $SeedPath = Join-Path $PSScriptRoot "exercises.seed.json"
}

function Normalize-Name([string]$Value) {
    if ($null -eq $Value) { return "" }
    return $Value.Trim().ToLowerInvariant()
}

function Get-AdminToken {
    param([string]$Email)

    if ([string]::IsNullOrWhiteSpace($Email)) {
        throw "AdminEmail is required unless DryRun is used."
    }

    $securePassword = Read-Host "Admin password" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($Email, $securePassword)
    $plainPassword = $credential.GetNetworkCredential().Password

    try {
        $loginBody = @{
            email = $Email
            password = $plainPassword
        } | ConvertTo-Json

        $response = Invoke-RestMethod `
            -Method Post `
            -Uri "$ApiBaseUrl/api/auth/login" `
            -ContentType "application/json; charset=utf-8" `
            -Body ([Text.Encoding]::UTF8.GetBytes($loginBody))

        $token = $response.token
        if ([string]::IsNullOrWhiteSpace($token)) {
            throw "Login response did not contain a token."
        }

        return $token
    }
    finally {
        $plainPassword = $null
    }
}

if (-not (Test-Path -LiteralPath $MusclesPath)) {
    throw "Muscles file not found: $MusclesPath"
}
if (-not (Test-Path -LiteralPath $SeedPath)) {
    throw "Exercise seed file not found: $SeedPath"
}

$muscles = Get-Content -Raw -Encoding utf8 -LiteralPath $MusclesPath | ConvertFrom-Json
$seed = Get-Content -Raw -Encoding utf8 -LiteralPath $SeedPath | ConvertFrom-Json

$muscleByName = @{}
foreach ($muscle in $muscles) {
    $key = Normalize-Name $muscle.name
    if ($muscleByName.ContainsKey($key)) {
        throw "Duplicate muscle name after normalization: $($muscle.name)"
    }
    $muscleByName[$key] = $muscle
}

$validationErrors = New-Object System.Collections.Generic.List[string]
foreach ($exercise in $seed) {
    $requiredMuscles = @($exercise.primaryMuscle) + @($exercise.secondaryMuscles)
    foreach ($muscleName in $requiredMuscles) {
        if (-not $muscleByName.ContainsKey((Normalize-Name $muscleName))) {
            $validationErrors.Add("$($exercise.name): unknown muscle '$muscleName'")
        }
    }
}

if ($validationErrors.Count -gt 0) {
    $validationErrors | ForEach-Object { Write-Error $_ }
    throw "Seed validation failed with $($validationErrors.Count) error(s)."
}

Write-Host "Validated $($seed.Count) exercises against $($muscles.Count) muscles." -ForegroundColor Green

if ($DryRun) {
    Write-Host "Dry run complete. No API requests were sent." -ForegroundColor Cyan
    exit 0
}

$token = Get-AdminToken -Email $AdminEmail
$headers = @{ Authorization = "Bearer $token" }
$existingExercises = @(Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/api/exercises")
$existingNames = @{}
foreach ($existing in $existingExercises) {
    $existingNames[(Normalize-Name $existing.name)] = $true
}

$created = 0
$skipped = 0
$failed = 0

foreach ($exercise in $seed) {
    $exerciseKey = Normalize-Name $exercise.name
    if ($existingNames.ContainsKey($exerciseKey)) {
        Write-Host "SKIP  $($exercise.name)" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    $secondaryMuscles = @($exercise.secondaryMuscles)
    $impacts = New-Object System.Collections.Generic.List[object]

    if ($secondaryMuscles.Count -eq 0) {
        $impacts.Add(@{
            muscleId = $muscleByName[(Normalize-Name $exercise.primaryMuscle)].id
            percentage = 100
        })
    }
    elseif ($secondaryMuscles.Count -eq 1) {
        $impacts.Add(@{
            muscleId = $muscleByName[(Normalize-Name $exercise.primaryMuscle)].id
            percentage = 70
        })
        $impacts.Add(@{
            muscleId = $muscleByName[(Normalize-Name $secondaryMuscles[0])].id
            percentage = 30
        })
    }
    else {
        $impacts.Add(@{
            muscleId = $muscleByName[(Normalize-Name $exercise.primaryMuscle)].id
            percentage = 60
        })
        foreach ($secondaryMuscle in $secondaryMuscles) {
            $impacts.Add(@{
                muscleId = $muscleByName[(Normalize-Name $secondaryMuscle)].id
                percentage = 20
            })
        }
    }

    $primaryDisplayName = $exercise.primaryMuscle.Trim()
    $payload = [ordered]@{
        name = $exercise.name
        equipment = $exercise.equipment
        difficulty = $exercise.difficulty
        description = "$($exercise.name) là bài tập tập trung chủ yếu vào $primaryDisplayName."
        instruction = "Thiết lập dụng cụ và tư thế ổn định. Thực hiện chuyển động chậm, có kiểm soát trong biên độ không gây đau; thở ra ở pha gắng sức và hít vào khi trở về."
        safetyNotes = "Ưu tiên kỹ thuật trước mức tạ. Dừng bài tập nếu đau nhói, chóng mặt hoặc mất kiểm soát tư thế."
        commonMistakes = "Dùng mức tạ quá nặng, thực hiện quá nhanh, nín thở hoặc đánh đổi tư thế để hoàn thành số lần lặp."
        tips = "Bắt đầu nhẹ, giữ nhịp ổn định và tăng tải dần khi hoàn thành toàn bộ số lần lặp với kỹ thuật tốt."
        defaultSets = [int]$exercise.sets
        defaultReps = [string]$exercise.reps
        restTimeSeconds = [int]$exercise.rest
        imageUrl = ""
        videoUrl = ""
        muscleImpacts = @($impacts)
    }

    $json = $payload | ConvertTo-Json -Depth 8

    try {
        Invoke-RestMethod `
            -Method Post `
            -Uri "$ApiBaseUrl/api/exercises" `
            -Headers $headers `
            -ContentType "application/json; charset=utf-8" `
            -Body ([Text.Encoding]::UTF8.GetBytes($json)) | Out-Null

        $existingNames[$exerciseKey] = $true
        $created++
        Write-Host "CREATE $($exercise.name)" -ForegroundColor Green
    }
    catch {
        $failed++
        Write-Host "FAIL  $($exercise.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Import summary: created=$created, skipped=$skipped, failed=$failed" -ForegroundColor Cyan

if ($failed -gt 0) {
    exit 1
}
