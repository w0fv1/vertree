# 设置 Inno Setup 编译器路径（请确认你的 Inno Setup 安装位置）
$innoSetupCompiler = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

# 保存当前脚本目录
$currentDir = Get-Location

# 回到上一层目录执行 flutter build windows
Set-Location ".."

Write-Host "正在执行 flutter build windows..."
flutter build windows

if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter编译失败，请检查错误日志。"
    Set-Location $currentDir
    exit $LASTEXITCODE
}

# 返回原脚本目录
Set-Location $currentDir

# 当前脚本目录
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ISS脚本路径（默认当前目录）
$issFile = Join-Path $scriptDir "setup.iss"

# 编译安装程序
Write-Host "正在使用Inno Setup进行打包..."
& $innoSetupCompiler $issFile

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