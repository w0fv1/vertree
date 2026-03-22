param(
    [ValidateSet("Debug","Profile","Release")]
    [string]$BuildMode = "Release",
    [switch]$Sparse,
    [switch]$SparseRefresh,
    [string]$Flutter = "",
    [string]$ISCC = "",
    [string]$WixBin = "",
    [string]$Target = "lib/main.dart"
)

# 设置 Inno Setup 编译器路径（请确认你的 Inno Setup 安装位置）
$innoSetupCompiler = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
$flutterDefault = "C:\flutter\bin\flutter.bat"

function Resolve-ToolPath([string]$preferred, [string]$fallbackPath, [string]$commandName) {
    if (-not [string]::IsNullOrWhiteSpace($preferred)) {
        return $preferred
    }
    $cmd = Get-Command $commandName -ErrorAction SilentlyContinue
    if ($cmd) {
        return $commandName
    }
    if (-not [string]::IsNullOrWhiteSpace($fallbackPath) -and (Test-Path $fallbackPath)) {
        return $fallbackPath
    }
    return ""
}

function Get-PubspecVersion([string]$projectRoot) {
    $pubspec = Join-Path $projectRoot "pubspec.yaml"
    if (-not (Test-Path $pubspec)) {
        throw "pubspec.yaml not found at $pubspec"
    }
    $line = Select-String -Path $pubspec -Pattern '^\s*version:\s*(.+?)\s*$' | Select-Object -First 1
    if (-not $line) {
        throw "pubspec.yaml missing 'version:'"
    }
    $raw = $line.Matches[0].Groups[1].Value
    return $raw.Trim().Trim("'").Trim('"')
}

function Get-VersionInfoVersion([string]$pubspecVersion) {
    $base = $pubspecVersion.Split('-')[0]
    $parts = $base.Split('.')
    if ($parts.Length -eq 3) {
        return ($base + ".0")
    }
    if ($parts.Length -eq 4) {
        return $base
    }
    # Fallback for unexpected schemas
    return "0.0.0.0"
}

function Get-MsiProductVersion([string]$pubspecVersion) {
    $baseVersion = $pubspecVersion
    $preRelease = ""
    if ($pubspecVersion.Contains('-')) {
        $parts = $pubspecVersion.Split('-', 2)
        $baseVersion = $parts[0]
        $preRelease = $parts[1]
    }

    $baseParts = $baseVersion.Split('.')
    if ($baseParts.Length -lt 3) {
        return "0.0.0"
    }

    $major = [int]$baseParts[0]
    $minor = [int]$baseParts[1]
    $patch = [int]$baseParts[2]

    $patchBucket = $patch * 100
    $preOffset = 99
    if (-not [string]::IsNullOrWhiteSpace($preRelease)) {
        $preLower = $preRelease.ToLowerInvariant()
        $baseWeight = 0
        if ($preLower.StartsWith("alpha")) {
            $baseWeight = 0
        } elseif ($preLower.StartsWith("beta")) {
            $baseWeight = 30
        } elseif ($preLower.StartsWith("rc")) {
            $baseWeight = 60
        } else {
            $baseWeight = 80
        }

        $match = [regex]::Match($preLower, '(\d+)$')
        $ordinal = if ($match.Success) { [int]$match.Groups[1].Value } else { 0 }
        $preOffset = [Math]::Min($baseWeight + $ordinal, 98)
    }

    return "$major.$minor.$($patchBucket + $preOffset)"
}

function Resolve-WixBin([string]$preferred) {
    if (-not [string]::IsNullOrWhiteSpace($preferred) -and (Test-Path $preferred)) {
        return $preferred
    }

    $candleCmd = Get-Command candle.exe -ErrorAction SilentlyContinue
    $lightCmd = Get-Command light.exe -ErrorAction SilentlyContinue
    $heatCmd = Get-Command heat.exe -ErrorAction SilentlyContinue
    if ($candleCmd -and $lightCmd -and $heatCmd) {
        return Split-Path -Parent $candleCmd.Source
    }

    foreach ($candidate in @(
        "C:\Program Files (x86)\WiX Toolset v3.14\bin",
        "C:\Program Files (x86)\WiX Toolset v3.11\bin"
    )) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return ""
}

function Escape-XmlAttribute([string]$value) {
    if ($null -eq $value) {
        return ""
    }
    return [System.Security.SecurityElement]::Escape($value)
}

# 当前脚本目录
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$currentDir = Get-Location

# 回到项目根目录执行 flutter build windows
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
Set-Location $projectRoot

$flutterCmd = Resolve-ToolPath -preferred $Flutter -fallbackPath $flutterDefault -commandName "flutter"
if ([string]::IsNullOrWhiteSpace($flutterCmd)) {
    throw "Flutter not found. Provide -Flutter <path> or ensure 'flutter' is in PATH."
}

$pubspecVersion = Get-PubspecVersion -projectRoot $projectRoot
$versionInfoVersion = Get-VersionInfoVersion -pubspecVersion $pubspecVersion
$msiProductVersion = Get-MsiProductVersion -pubspecVersion $pubspecVersion
$setupBaseName = "vertree-windows-x64-$pubspecVersion-setup"
$zipBaseName = "vertree-windows-x64-$pubspecVersion"
$msiBaseName = "vertree-windows-x64-$pubspecVersion"
Write-Host "pubspec.yaml version=$pubspecVersion"
Write-Host "VersionInfoVersion=$versionInfoVersion"
Write-Host "MsiProductVersion=$msiProductVersion"
Write-Host "Windows setup artifact=$setupBaseName.exe"
Write-Host "Windows zip artifact=$zipBaseName.zip"
Write-Host "Windows MSI artifact=$msiBaseName.msi"

Write-Host "正在执行 flutter build windows ($BuildMode)..."
& $flutterCmd build windows --target $Target --$($BuildMode.ToLower())

if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter编译失败，请检查错误日志。"
    Set-Location $currentDir
    exit $LASTEXITCODE
}

# 返回脚本目录
Set-Location $scriptDir

# ISS脚本路径（默认当前目录）
$issFile = Join-Path $scriptDir "setup.iss"

# Copy context menu DLL into runner output (if built).
$contextMenuDll = Join-Path $scriptDir "..\\build\\windows\\x64\\context_menu\\$BuildMode\\vertree_context_menu.dll"
$runnerDll = Join-Path $scriptDir "..\\build\\windows\\x64\\runner\\$BuildMode\\vertree_context_menu.dll"
if (Test-Path $contextMenuDll) {
    try {
        Copy-Item $contextMenuDll $runnerDll -Force -ErrorAction Stop
        Write-Host "已复制右键菜单 DLL 到 Runner 目录"
    } catch {
        Write-Warning "复制右键菜单 DLL 失败（可能被 Explorer/DllHost 占用），尝试释放占用并重试..."
        try {
            try {
                & taskkill.exe /F /IM dllhost.exe /FI "MODULES eq vertree_context_menu.dll" | Out-Null
                Write-Host "已尝试结束加载 vertree_context_menu.dll 的 DllHost"
            } catch {
                Write-Warning "结束 DllHost 失败（可忽略）：$($_.Exception.Message)"
            }

            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            try {
                Copy-Item $contextMenuDll $runnerDll -Force -ErrorAction Stop
                Write-Host "已复制右键菜单 DLL 到 Runner 目录"
            } catch {
                Write-Warning "重启 Explorer 后仍无法复制 DLL（可能仍被占用）。"
            } finally {
                Start-Process explorer.exe | Out-Null
            }
            Write-Host "已重启 Explorer 并复制 DLL"
        } catch {
            Write-Warning "重启 Explorer 后仍无法复制 DLL，请手动重启后重试构建。"
        }
    }
}

# Copy Win11 sparse package resources into runner output so installed builds
# can self-register the packaged Explorer menu on end-user machines.
$packagingSourceDir = Join-Path $scriptDir "packaging"
$packagingTargetDir = Join-Path $scriptDir "..\\build\\windows\\x64\\runner\\$BuildMode\\win11_packaging"
if (Test-Path $packagingSourceDir) {
    try {
        if (Test-Path $packagingTargetDir) {
            Remove-Item $packagingTargetDir -Recurse -Force
        }
        New-Item -ItemType Directory -Force -Path $packagingTargetDir | Out-Null
        Copy-Item (Join-Path $packagingSourceDir "*") $packagingTargetDir -Recurse -Force
        Write-Host "已复制 Win11 sparse package 资源到 Runner 目录"
    } catch {
        Write-Warning "复制 Win11 sparse package 资源失败：$($_.Exception.Message)"
    }
}

if (-not (Test-Path $innoSetupCompiler)) {
    $isccCmd = Resolve-ToolPath -preferred $ISCC -fallbackPath "" -commandName "ISCC"
    if ([string]::IsNullOrWhiteSpace($isccCmd)) {
        Write-Warning "未找到 Inno Setup 编译器: $innoSetupCompiler，跳过安装包打包。"
        $innoSetupCompiler = ""
    } else {
        $innoSetupCompiler = $isccCmd
    }
}

if ([string]::IsNullOrWhiteSpace($innoSetupCompiler)) {
} else {
# 编译安装程序
Write-Host "正在使用Inno Setup进行打包..."
& $innoSetupCompiler /DBuildMode=$BuildMode /DAppVersion=$pubspecVersion /DAppVersionInfoVersion=$versionInfoVersion /DOutputBaseFilename=$setupBaseName $issFile

    if ($LASTEXITCODE -eq 0) {
        Write-Host "打包成功！开始压缩为Zip..."

        # 安装程序路径（注意与setup.iss中的OutputBaseFilename一致）
        $setupExe = Join-Path $scriptDir "$setupBaseName.exe"

        # 输出Zip路径
        $zipFile = Join-Path $scriptDir "$zipBaseName.zip"

        # 检查已有zip文件，如存在则删除
        if (Test-Path $zipFile) {
            Remove-Item $zipFile -Force
        }

        # 压缩为zip
        Compress-Archive -Path $setupExe -DestinationPath $zipFile

        Write-Host "压缩完成：" $zipFile
    } else {
        Write-Error "打包失败！请检查上方日志。"
    }
}

$wixBin = Resolve-WixBin -preferred $WixBin
if ([string]::IsNullOrWhiteSpace($wixBin)) {
    Write-Warning "未找到 WiX Toolset，跳过 MSI 打包。"
} else {
    $heatExe = Join-Path $wixBin "heat.exe"
    $candleExe = Join-Path $wixBin "candle.exe"
    $lightExe = Join-Path $wixBin "light.exe"
    $productWxs = Join-Path $scriptDir "installer\\Product.wxs"
    $wixObjDir = Join-Path $scriptDir "..\\build\\windows\\wix"
    $harvestWxs = Join-Path $wixObjDir "AppFiles.wxs"
    $runnerDir = Resolve-Path (Join-Path $scriptDir "..\\build\\windows\\x64\\runner\\$BuildMode")
    $msiPath = Join-Path $scriptDir "$msiBaseName.msi"

    if ((-not (Test-Path $heatExe)) -or (-not (Test-Path $candleExe)) -or (-not (Test-Path $lightExe))) {
        Write-Warning "WiX Toolset 缺少 heat/candle/light，可执行文件不完整，跳过 MSI 打包。"
    } else {
        New-Item -ItemType Directory -Force -Path $wixObjDir | Out-Null
        $resolvedProjectRoot = (Resolve-Path $projectRoot).Path
        $productGeneratedWxs = Join-Path $wixObjDir "Product.generated.wxs"
        if (Test-Path $harvestWxs) {
            Remove-Item $harvestWxs -Force
        }
        if (Test-Path $msiPath) {
            Remove-Item $msiPath -Force
        }
        if (Test-Path $productGeneratedWxs) {
            Remove-Item $productGeneratedWxs -Force
        }

        $productTemplate = Get-Content $productWxs -Raw
        $productTemplate = $productTemplate.Replace('$(var.ProductVersion)', (Escape-XmlAttribute $msiProductVersion))
        $productTemplate = $productTemplate.Replace('$(var.FullVersion)', (Escape-XmlAttribute $pubspecVersion))
        $productTemplate = $productTemplate.Replace('$(var.RootDir)', (Escape-XmlAttribute $resolvedProjectRoot))
        [System.IO.File]::WriteAllText(
            $productGeneratedWxs,
            $productTemplate,
            [System.Text.UTF8Encoding]::new($false)
        )

        Write-Host "正在使用 WiX 生成 MSI..."
        & $heatExe dir $runnerDir `
            -nologo `
            -gg `
            -g1 `
            -srd `
            -scom `
            -sreg `
            -cg AppFiles `
            -dr INSTALLDIR `
            -var var.SourceDir `
            -out $harvestWxs

        if ($LASTEXITCODE -ne 0) {
            Write-Error "heat 收集安装文件失败。"
            exit $LASTEXITCODE
        }

        & $candleExe `
            -nologo `
            -arch x64 `
            -dSourceDir=$runnerDir `
            -out "$wixObjDir\\" `
            $productGeneratedWxs `
            $harvestWxs

        if ($LASTEXITCODE -ne 0) {
            Write-Error "candle 编译 MSI 安装文件失败。"
            exit $LASTEXITCODE
        }

        & $lightExe `
            -nologo `
            -cultures:en-us `
            -out $msiPath `
            (Join-Path $wixObjDir "Product.wixobj") `
            (Join-Path $wixObjDir "AppFiles.wixobj")

        if ($LASTEXITCODE -ne 0) {
            Write-Error "light 链接 MSI 安装包失败。"
            exit $LASTEXITCODE
        }

        Write-Host "MSI 打包完成：" $msiPath
    }
}

if ($Sparse -or $SparseRefresh) {
    $externalLocation = Resolve-Path (Join-Path $scriptDir "..\\build\\windows\\x64\\runner\\$BuildMode")

    if ($SparseRefresh) {
        $refreshScript = Join-Path $scriptDir "packaging\\refresh_win11_menu.ps1"
        if (-not (Test-Path $refreshScript)) {
            Write-Warning "未找到 Win11 菜单刷新脚本: $refreshScript"
            exit 0
        }
        Write-Host "刷新 Win11 新菜单（Sparse Package），ExternalLocation=$externalLocation"
        & $refreshScript -BuildMode $BuildMode -ExternalLocation $externalLocation
    } else {
        $sparseScript = Join-Path $scriptDir "packaging\\install_sparse_package.ps1"
        if (-not (Test-Path $sparseScript)) {
            Write-Warning "未找到 Sparse Package 脚本: $sparseScript"
            exit 0
        }
        Write-Host "注册 Sparse Package，ExternalLocation=$externalLocation"
        & $sparseScript -ExternalLocation $externalLocation -Force
    }
}
