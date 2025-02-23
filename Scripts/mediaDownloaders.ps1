# Для корректной работы скрипта запустите его в STA: 
# powershell.exe -STA -WindowStyle Hidden -File "C:\Path\to\script.ps1"

# Подключаем необходимые сборки
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Функция запуска приложения, если оно ещё не запущено
function Start-AppIfNotRunning {
    param (
        [string]$processName,
        [string]$executablePath
    )
    if (-not (Get-Process -Name $processName -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $executablePath
    }
}

# Определяем приложения и их параметры
$apps = @{
    "Prowlarr"    = @{ ProcessName = "prowlarr";    Path = "C:\ProgramData\Prowlarr\bin\Prowlarr.exe"; Hidden = $false }
    "Sonarr"      = @{ ProcessName = "sonarr";      Path = "C:\ProgramData\Sonarr\bin\Sonarr.exe"; Hidden = $false }
    "Radarr"      = @{ ProcessName = "radarr";      Path = "C:\ProgramData\Radarr\bin\Radarr.exe"; Hidden = $false }
    "qBittorrent" = @{ ProcessName = "qbittorrent"; Path = "C:\Program Files\qBittorrent\qbittorrent.exe"; Hidden = $false }
}

# Запускаем приложения, если они не запущены
foreach ($app in $apps.GetEnumerator()) {
    Start-AppIfNotRunning -processName $app.Value.ProcessName -executablePath $app.Value.Path -Hidden:$app.Value.Hidden
}

# Создаем контекстное меню для иконки в трее
$contextMenu = New-Object System.Windows.Forms.ContextMenu

# Для каждого приложения добавляем пункт меню для его закрытия
foreach ($app in $apps.GetEnumerator()) {
    $menuItem = New-Object System.Windows.Forms.MenuItem $app.Key
    $menuItem.Add_Click({
        $proc = Get-Process -Name $app.Value.ProcessName -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | Stop-Process -Force
        }
    })
    $contextMenu.MenuItems.Add($menuItem)
}

# Добавляем кнопку "Закрыть все"
$closeAllMenuItem = New-Object System.Windows.Forms.MenuItem "Close All"
$closeAllMenuItem.Add_Click({
    foreach ($app in $apps.GetEnumerator()) {
        $proc = Get-Process -Name $app.Value.ProcessName -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | Stop-Process -Force
        }
    }
    # Закрываем сам скрипт
    $notifyIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})
$contextMenu.MenuItems.Add("-")  # Разделитель
$contextMenu.MenuItems.Add($closeAllMenuItem)

# Добавляем разделитель и пункт для выхода из скрипта
$exitMenuItem = New-Object System.Windows.Forms.MenuItem "Exit"
$exitMenuItem.Add_Click({
    # Убираем иконку из трея и завершаем приложение
    $notifyIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})
$contextMenu.MenuItems.Add("-")  # Разделитель
$contextMenu.MenuItems.Add($exitMenuItem)

# Создаем и настраиваем иконку трея
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Text = "Скрипт управления сервисами"
$notifyIcon.ContextMenu = $contextMenu
$notifyIcon.Visible = $true

# Запускаем цикл обработки сообщений, чтобы скрипт «висел» в трее
[System.Windows.Forms.Application]::Run()
