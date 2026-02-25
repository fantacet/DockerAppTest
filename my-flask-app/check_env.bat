@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
echo ===================================================
echo      Docker 佈署環境必要條件檢查 (Windows)
echo ===================================================
echo.

set FAIL_COUNT=0

REM 1. 檢查 WSL
echo [1/5] 檢查 WSL (Windows Subsystem for Linux) ...
wsl --status >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo   [X] 找不到 WSL 或 WSL 未啟動。
    echo       請使用系統管理員開啟 PowerShell 並執行: wsl --install
    set /a FAIL_COUNT+=1
) else (
    echo   [O] WSL 已安裝並且正常運作。
)

REM 2. 檢查 Docker CLI
echo [2/5] 檢查 Docker Engine (CLI) ...
docker --version >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo   [!] 在 Windows PATH 中找不到 docker 指令。
    echo       ^<若您打算完全在 WSL 的 Ubuntu 內執行指令，此項可以忽略^>
) else (
    echo   [O] Docker CLI 在 Windows 端可用。
)

REM 3. 檢查 WSL 內的 Docker 服務
echo [3/5] 檢查 WSL 內的 Docker 服務狀態 ...
wsl -e bash -c "service docker status 2>/dev/null | grep 'is running'" >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    wsl -e bash -c "systemctl is-active docker 2>/dev/null | grep 'active'" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo   [!] WSL 內的 Docker 背景服務可能未啟動，或您尚在 WSL 中安裝 Docker。
        echo       ^<請在 Ubuntu 終端機內執行: sudo service docker start^>
        set /a FAIL_COUNT+=1
    ) else (
        echo   [O] WSL 內的 Docker 服務正在運行。
    )
) else (
    echo   [O] WSL 內的 Docker 服務正在運行。
)

REM 4. 檢查 .env 設定檔
echo [4/5] 檢查 .env 環境變數設定檔 ...
if not exist ".env" (
    echo   [X] 找不到 .env 檔案。請確保專案根目錄下有此檔案。
    set /a FAIL_COUNT+=1
) else (
    echo   [O] .env 檔案已存在。
)

REM 5. 檢查系統記憶體
echo [5/5] 檢查系統實體記憶體容量 ...
set "MEM_KB="
for /f "tokens=2 delims==" %%A in ('wmic OS get TotalVisibleMemorySize /Value 2^>nul') do set "MEM_KB=%%A"
if defined MEM_KB (
    set /a "MEM_GB=MEM_KB / 1048576"
    if !MEM_GB! LSS 1 (
         echo   [X] 系統記憶體不足 1GB ^(目前: !MEM_GB! GB^)，可能無法穩定運行所有容器。
         set /a FAIL_COUNT+=1
    ) else (
         echo   [O] 系統記憶體充足 ^(目前: !MEM_GB! GB^)。
    )
) else (
    echo   [?] 無法自動偵測系統記憶體，請手動確認。
)

echo.
echo ===================================================
if !FAIL_COUNT! EQU 0 (
    echo [OK] 檢查通過！您的主機環境具備基本的佈署條件。
    echo      您可以直接開啟 Ubuntu 終端機，執行 'docker compose up -d' 開始佈署。
) else (
    echo [警告] 發現 !FAIL_COUNT! 個不符合的條件，請參考上方指示修正後再試。
)
echo ===================================================
pause
