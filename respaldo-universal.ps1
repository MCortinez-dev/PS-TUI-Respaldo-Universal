# ==============================================================================
# ASISTENTE INTERACTIVO DE RESPALDO UNIVERSAL
# Desarrollado por: MCortinez-dev (https://github.com/MCortinez-dev)
# Opciones de Navegacion: 'B' para Volver, 'X' para Salir en cualquier menu.
# ==============================================================================

$paso = 1
$salir = $false

$rutaRaiz = ""
$listaExcluidas = @()
$destinoFinal = ""
$esRsync = $false

# Funcion interna para mantener la firma visual unificada en cada pantalla
function Mostrar-Footer {
    Write-Host "---------------------------------------------------------"
    Write-Host " Desarrollado por: MCortinez-dev | GitHub: https://github.com/MCortinez-dev" -ForegroundColor DarkGray
    Write-Host "=========================================================" -ForegroundColor Green
}

while (-not $salir) {
    switch ($paso) {
        
        # ----------------------------------------------------------------------
        # PASO 1: SELECCION DE ORIGEN
        # ----------------------------------------------------------------------
        1 {
            Clear-Host
            Write-Host "=========================================================" -ForegroundColor Green
            Write-Host "   PASO 1: SELECCION DE ORIGEN                            " -ForegroundColor Green
            Write-Host "=========================================================" -ForegroundColor Green
            Write-Host " [X] Salir" -ForegroundColor Red
            Write-Host "---------------------------------------------------------"
            Write-Host ""

            $discos = Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.DriveType -eq "Fixed" }
            $i = 1
            foreach ($disco in $discos) {
                $tamanoGB = [Math]::Round($disco.Size / 1GB, 1)
                $libreGB  = [Math]::Round($disco.SizeRemaining / 1GB, 1)
                Write-Host " $i = Unidad $($disco.DriveLetter): [Etiqueta: $($disco.FileSystemLabel)] | Total: $tamanoGB GB | Libre: $libreGB GB" -ForegroundColor Cyan
                $i++
            }
            Write-Host ""
            
            Mostrar-Footer
            $seleccion = Read-Host "Selecciona el numero de origen o 'X' para salir"
            
            if ($seleccion -eq "x") { $salir = $true }
            elseif ($seleccion -match "^\d+$" -and [int]$seleccion -ge 1 -and [int]$seleccion -lt $i) {
                $rutaRaiz = $discos[[int]$seleccion - 1].DriveLetter + ":\"
                $paso = 2
            } else {
                Write-Host "`nOpcion invalida. Reintenta." -ForegroundColor Red; Start-Sleep -Seconds 1
            }
        }

        # ----------------------------------------------------------------------
        # PASO 2: EXCLUSIONES MULTIPLES
        # ----------------------------------------------------------------------
        2 {
            $carpetas = Get-ChildItem -Path $rutaRaiz | Where-Object { $_.PSIsContainer }
            
            while ($true) {
                Clear-Host
                Write-Host "=========================================================" -ForegroundColor Green
                Write-Host "   PASO 2: SELECCION DE EXCLUSIONES (OPCIONAL)           " -ForegroundColor Green
                Write-Host "=========================================================" -ForegroundColor Green
                Write-Host " [B] Volver al Paso Anterior  |  [X] Salir" -ForegroundColor Red
                Write-Host "---------------------------------------------------------"
                Write-Host "Origen seleccionado: $rutaRaiz" -ForegroundColor Gray
                Write-Host ""
                
                $j = 1
                foreach ($carpeta in $carpetas) {
                    Write-Host " $j = $($carpeta.Name)" -ForegroundColor Cyan
                    $j++
                }
                Write-Host ""
                if ($listaExcluidas.Count -gt 0) {
                    Write-Host "Exclusiones actuales: [ $($listaExcluidas -join ', ') ]" -ForegroundColor Yellow
                    Write-Host ""
                }

                Mostrar-Footer
                $selCarpeta = Read-Host "Numero de carpeta a excluir (O Enter para continuar al Destino)"
                
                if ($selCarpeta -eq "b") { $paso = 1; break }
                if ($selCarpeta -eq "x") { $salir = $true; break }
                if ($selCarpeta -eq "") { $paso = 3; break }

                if ($selCarpeta -match "^\d+$" -and [int]$selCarpeta -ge 1 -and [int]$selCarpeta -lt $j) {
                    $carpetaExcluida = $carpetas[[int]$selCarpeta - 1].Name
                    if ($listaExcluidas -notcontains $carpetaExcluida) { $listaExcluidas += $carpetaExcluida }
                }
            }
        }

        # ----------------------------------------------------------------------
        # PASO 3: TIPO Y RUTA DE DESTINO
        # ----------------------------------------------------------------------
        3 {
            Clear-Host
            Write-Host "=========================================================" -ForegroundColor Green
            Write-Host "   PASO 3: TIPO DE DESTINO DE RESPALDO                    " -ForegroundColor Green
            Write-Host "=========================================================" -ForegroundColor Green
            Write-Host " [B] Volver al Paso Anterior  |  [X] Salir" -ForegroundColor Red
            Write-Host "---------------------------------------------------------"
            Write-Host ""
            Write-Host " 1 = Unidad Local / Externa (Otro disco, Pendrive, USB)" -ForegroundColor Cyan
            Write-Host " 2 = Red Local SMB (Servidor NAS, carpeta compartida)" -ForegroundColor Cyan
            Write-Host " 3 = Tunel VPN / Tailscale / SSH Remoto (Rsync)" -ForegroundColor Cyan
            Write-Host ""

            Mostrar-Footer
            $tipoDestino = Read-Host "Selecciona el tipo de destino (1-3)"

            if ($tipoDestino -eq "b") { $paso = 2; continue }
            if ($tipoDestino -eq "x") { $salir = $true; continue }

            $esRsync = $false
            switch ($tipoDestino) {
                "1" { 
                    Write-Host "`nEjemplo: E:\Backup o G:\MiCopia" -ForegroundColor Gray
                    $destinoFinal = Read-Host "Ingresa la ruta de destino local"
                }
                "2" { 
                    Write-Host "`nEjemplo: \\192.168.1.50\MiCarpetaCompartida" -ForegroundColor Gray
                    $destinoFinal = Read-Host "Ingresa la ruta UNC de red"
                }
                "3" { 
                    Write-Host "`nEjemplo: usuario@100.120.45.10:/ruta/servidor/backup" -ForegroundColor Gray
                    $destinoFinal = Read-Host "Ingresa el destino SSH/Rsync completo"
                    $esRsync = $true
                }
                Default { 
                    Write-Host "`nOpcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1; continue 
                }
            }

            if ($destinoFinal -eq "b") { $paso = 3; continue }
            if ($destinoFinal -eq "x") { $salir = $true; continue }

            if ($esRsync -or (Test-Path -Path $destinoFinal -ErrorAction SilentlyContinue)) {
                $paso = 4
            } else {
                Write-Host "`nERROR: El destino no es accesible o no existe." -ForegroundColor Red
                Read-Host "Presiona Enter para intentar de nuevo"
            }
        }

        # ----------------------------------------------------------------------
        # PASO 4: VISTA PREVIA Y EJECUCION
        # ----------------------------------------------------------------------
        4 {
            if ($esRsync) {
                $exclusionesRsync = ""
                foreach ($exc in $listaExcluidas) { $exclusionesRsync += " --exclude='$exc'" }
                $comandoFinal = "rsync -avzP$exclusionesRsync `"$rutaRaiz`" `"$destinoFinal`""
                $motor = "Rsync (via SSH/Tailscale)"
            } else {
                $exclusionesRobo = ""
                if ($listaExcluidas.Count -gt 0) { 
                    $listaQuoted = $listaExcluidas | ForEach-Object { "`"$_`"" }
                    $exclusionesRobo = " /XD " + ($listaQuoted -join " ")
                }
                $comandoFinal = "robocopy `"$rutaRaiz`" `"$destinoFinal`" /MIR /R:3 /W:5$exclusionesRobo"
                $motor = "Robocopy (Nativo de Windows)"
            }

            Clear-Host
            Write-Host "=========================================================" -ForegroundColor Green
            Write-Host "   PASO 4: VISTA PREVIA Y EJECUCION                      " -ForegroundColor Green
            Write-Host "=========================================================" -ForegroundColor Green
            Write-Host " [B] Volver al Paso Anterior  |  [X] Salir" -ForegroundColor Red
            Write-Host "---------------------------------------------------------"
            Write-Host " Origen:    $rutaRaiz" -ForegroundColor Cyan
            Write-Host " Destino:   $destinoFinal" -ForegroundColor Cyan
            Write-Host " Motor:     $motor" -ForegroundColor Gray
            if ($listaExcluidas.Count -gt 0) {
                Write-Host " Excluidos: [ $($listaExcluidas -join ', ') ]" -ForegroundColor Yellow
            }
            Write-Host "---------------------------------------------------------"
            Write-Host "COMANDO CONFIGURADO:" -ForegroundColor Yellow
            Write-Host $comandoFinal -ForegroundColor Magenta
            Write-Host "---------------------------------------------------------"
            Write-Host " AVISO IMPORTANTE SOBRE ESTA COPIA:" -ForegroundColor Green
            Write-Host " * El proceso mostrara el progreso archivo por archivo en tiempo real abajo." -ForegroundColor Gray
            Write-Host " * El comando esta configurado en modo ESPEJO (/MIR o -avz)." -ForegroundColor Gray
            Write-Host " * SI LA CONEXION SE CORTA, PODES VOLVER A CORRER EL SCRIPT." -ForegroundColor Green
            Write-Host "   El motor reanudara exactamente donde dejo sin duplicar datos." -ForegroundColor Green
            Write-Host "---------------------------------------------------------"
            Write-Host ""
            Write-Host " 1 = Ejecutar la copia de seguridad ahora mismo" -ForegroundColor Cyan
            Write-Host " 2 = Salir y copiar el comando manualmente" -ForegroundColor Cyan
            Write-Host ""
            
            Mostrar-Footer
            $ejecutar = Read-Host "Selecciona una opcion"

            if ($ejecutar -eq "b") { $paso = 3; continue }
            if ($ejecutar -eq "x" -or $ejecutar -eq "2") { $salir = $true; continue }

            if ($ejecutar -eq "1") {
                Write-Host "`n[!] Ejecutando proceso. Monitorea el progreso abajo...`n" -ForegroundColor Yellow
                Invoke-Expression $comandoFinal
                Write-Host "`n=========================================================" -ForegroundColor Green
                Write-Host "  PROCESO FINALIZADO CON EXITO" -ForegroundColor Green
                Write-Host "=========================================================" -ForegroundColor Green
                Mostrar-Footer
                Read-Host "Presiona Enter para cerrar el asistente"
                $salir = $true
            }
        }
    }
}

Clear-Host
Write-Host "Asistente finalizado. Desarrollado por MCortinez-dev." -ForegroundColor Gray