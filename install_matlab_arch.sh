#!/bin/bash

# ==============================================================================
# Instalador y Activador de MATLAB R2025b para CachyOS / Arch Linux
# ==============================================================================
# PROBLEMA: MATLAB R2025b usa un administrador de licencias (FlexNet) obsoleto
# que choca con las librerías modernas de Arch (glibc 2.43+) y entra en pánico
# al no encontrar las interfaces de red antiguas, resultando en un "Segmentation
# violation" (lc_new_job).
# SOLUCIÓN: Usamos Distrobox con Ubuntu 24.04 como "Caballo de Troya" para
# burlar la seguridad, generar el archivo de licencia en nuestro /home, y
# luego destruimos el contenedor para correr MATLAB 100% nativo.
# ==============================================================================

MATLAB_DIR="$HOME/matlab"
UBUNTU_BOX="matlab-box"

echo "🚀 Iniciando la instalación épica de MATLAB R2025b..."
sleep 2

# 1. Descargar mpm (MathWorks Package Manager) si no existe
if [ ! -f "mpm" ]; then
    echo "📦 Descargando el gestor de paquetes mpm..."
    wget -qO mpm https://www.mathworks.com/mpm/glnxa64/mpm
    chmod +x mpm
fi

# 2. Instalar MATLAB base y Toolboxes esenciales
# Puedes agregar más toolboxes en la lista separada por espacios
echo "⚙️ Instalando MATLAB y Toolboxes..."
./mpm install --release=R2025b --destination=$MATLAB_DIR --products MATLAB Simulink Communications_Toolbox DSP_System_Toolbox

# 3. Preparar el Caballo de Troya (Distrobox + Podman)
echo "🛡️ Instalando dependencias del sistema anfitrión (CachyOS/Arch)..."
sudo pacman -S --needed distrobox podman net-tools rtl-sdr --noconfirm

echo "📦 Creando el contenedor de Ubuntu 24.04 (El Caballo de Troya)..."
distrobox create --name $UBUNTU_BOX --image ubuntu:24.04 --yes

# 4. Inyectar dependencias dentro de Ubuntu e iniciar el activador
echo "🔑 Entrando al contenedor para instalar librerías antiguas y activar..."
echo "⚠️ ATENCIÓN: Se abrirá la ventana de MathWorks. Inicia sesión para activar."
echo "⚠️ Cuando termines y MATLAB diga que está activado, CIERRA LA VENTANA."

distrobox enter $UBUNTU_BOX -- bash -c "sudo apt update && sudo apt install -y libxt6 libxext6 libsm6 libglib2.0-0 libnss3 net-tools libcrypt-dev libasound2t64 libatk1.0-0 libcairo2 libcups2 libdbus-1-3 libxcomposite1 libxcursor1 libxdamage1 libxrandr2 libgbm1 libxft2 libxss1 libxtst6 && $MATLAB_DIR/bin/matlab -activate"

# 5. Destrucción del contenedor y limpieza
echo "🧹 Activación completada. Destruyendo el Caballo de Troya para liberar espacio..."
distrobox rm $UBUNTU_BOX --force
podman rmi ubuntu:24.04

# 6. Creación del acceso directo nativo para KDE / GNOME
echo "🖥️ Creando icono de acceso directo nativo..."
cat <<EOF > ~/.local/share/applications/matlab-nativo.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=MATLAB R2025b
Comment=Ejecutado nativamente en CachyOS
Exec=$MATLAB_DIR/bin/matlab -desktop
Icon=utilities-terminal
Terminal=false
Categories=Development;Education;Science;Math;
EOF

echo "✅ ¡Misión Cumplida! MATLAB R2025b está instalado 100%."
echo "Puedes iniciarlo desde el menú de aplicaciones de tu sistema."
