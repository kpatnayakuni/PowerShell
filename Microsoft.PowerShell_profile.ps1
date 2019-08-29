Write-Host ""
Write-Host " _    _   _   _____   ______   __      _" -ForegroundColor Yellow
Write-Host "| |  / / | | |  _  | |  __  | |   \   | |" -ForegroundColor Yellow
Write-Host "| |_/ /  | | | |_| | | |__| | | |\ \  | |" -ForegroundColor Yellow
Write-Host "|  _ /   | | |   __| |  __  | | | \ \ | |" -ForegroundColor Yellow
Write-Host "| | \ \  | | | |\ \  | |  | | | |  \ \| |" -ForegroundColor Yellow
Write-Host "|_|  \_\ |_| |_| \_\ |_|  |_| |_|   \ __|" -ForegroundColor Yellow
Write-Host ""
Write-Host "       *" -ForegroundColor Red
Write-Host "      /.\" -ForegroundColor Red -NoNewline; Write-Host "       Author: " -ForegroundColor Green -NoNewline; Write-Host "Kiran Patnayakuni" -ForegroundColor Magenta
Write-Host "     /..'\" -ForegroundColor Red -NoNewline; Write-Host "        Date: " -ForegroundColor Green -NoNewline; Write-Host "$((Get-Date).ToString(`"dd/MM/yyyy`"))" -ForegroundColor Magenta
Write-Host "     /'.'\" -ForegroundColor Red -NoNewline; Write-Host "               .-." -ForegroundColor Yellow
Write-Host "    /.''.'\" -ForegroundColor Red -NoNewline; Write-Host "            _( `" )_" -ForegroundColor Yellow
Write-Host "    /.'.'.\" -ForegroundColor Red -NoNewline; Write-Host "           (_  :  _)" -ForegroundColor Green
Write-Host "   /'.''.'.\" -ForegroundColor Red -NoNewline; Write-Host "             /'\" -ForegroundColor Red
Write-Host "   ^^^[_]^^^" -ForegroundColor Red -NoNewline; Write-Host "           (_/^\_)" -ForegroundColor Red
Write-Host ""
Write-Host " Hi Kiran, Welcome back...!"
Write-Host ""

Function prompt
{
    $History = @(Get-History)
    if ($History.Count -gt 0)
    {
        $LastItem = $History[-1]
        $LastID = $LastItem.Id
    }
    $CMDNo = $LastID++
    $CurrentDirectory = Get-Location
    $CMDDate = $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
    Write-Host ''
    Write-Host $CMDDate
    Write-Host "[ K I R A N ] ($CMDNo) $CurrentDirectory> " -NoNewline
    " "
    if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        Write-Host -ForegroundColor Red -BackgroundColor Yellow -Object "!!!Please run as Administrator!!!`n" -NoNewline
    }
}

Start-Transcript