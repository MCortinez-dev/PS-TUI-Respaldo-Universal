# Asistente Interactivo de Respaldo Universal (TUI)

Un script interactivo en PowerShell diseñado para simplificar y automatizar la ejecución de copias de seguridad unificando tres entornos críticos: almacenamiento local/externo, red local (SMB) y servidores remotos a través de **Tailscale SSH** y **Rsync**.

## 🚀 Características
*   **Interfaz de Consola (TUI):** Flujo guiado paso a paso con manejo de estado nativo en PowerShell.
*   **Detección Automática de Hardware:** Mapea las unidades fijas locales, tamaños y espacio libre en tiempo real.
*   **Exclusiones Inteligentes:** Permite seleccionar directorios dinámicamente y formatea las rutas complejas con espacios para evitar fallas en los motores de copia.
*   **Motor Dual Robocopy / Rsync:** 
    *   Usa **Robocopy** con modificadores de espejo (`/MIR`) y reanudación automática para entornos Windows y redes SMB.
    *   Usa **Rsync** estructurado sobre SSH para transferencias eficientes hacia servidores remotos (ideal para infraestructuras Linux/HomeLabs sobre Tailscale).

## 🛠️ Requisitos
*   **Windows 10/11** con PowerShell 5.1 o superior.
*   Para respaldos remotos: **Tailscale** activo y configuración de SSH habilitada en el destino.

## 📦 Instalación y Uso
1. Clona este repositorio:
   ```bash
   git clone [https://github.com/MCortinez-dev/PS-TUI-Respaldo-Universal.git](https://github.com/MCortinez-dev/PS-TUI-Respaldo-Universal.git)
   ```
2. Abre una terminal de PowerShell como Administrador, navega a la carpeta y ejecuta:

   ```PowerShell
   Set-ExecutionPolicy Bypass -Scope Process .\respaldo-universal.ps1
   ```

Desarrollado con 💪 por MCortinez-dev
