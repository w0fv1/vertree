param(
    [ValidateSet("Debug","Profile","Release")]
    [string]$BuildMode = "Release",
    [switch]$Sparse,
    [switch]$SparseRefresh
)

# 设置 Inno Setup 编译器路径（请确认你的 Inno Setup 安装位置）
$innoSetupCompiler = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
$flutter = "C:\flutter\bin\flutter.bat"

# 当前脚本目录
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 回到项目根目录执行 flutter build windows
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
Set-Location $projectRoot

Write-Host "正在执行 flutter build windows ($BuildMode)..."
& $flutter build windows --$($BuildMode.ToLower())

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

if (-not (Test-Path $innoSetupCompiler)) {
    Write-Warning "未找到 Inno Setup 编译器: $innoSetupCompiler，跳过安装包打包。"
} else {
# 编译安装程序
Write-Host "正在使用Inno Setup进行打包..."
& $innoSetupCompiler /DBuildMode=$BuildMode $issFile

    if ($LASTEXITCODE -eq 0) {
        Write-Host "打包成功！开始压缩为Zip..."

        # 安装程序路径（注意与setup.iss中的OutputBaseFilename一致）
        $setupExe = Join-Path $scriptDir "Vertree_Setup.exe"

        # 输出Zip路径
        $zipFile = Join-Path $scriptDir "Vertree_Setup.zip"

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
