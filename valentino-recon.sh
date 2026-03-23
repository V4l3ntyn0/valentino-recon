#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# VALENTINO-RECON v1.0 - Red Team Recon Tool by José Luis Valentino Hernández
# Especialista Ciberseguridad | ISO 27001 | NIST | 20+ años experiencia
# Instalación: chmod +x valentino-recon.sh && sudo mv valentino-recon.sh /usr/local/bin/valentino-recon
# Uso: sudo valentino-recon --anon <target> [nmap flags]
# GitHub: https://github.com/tuusuario/valentino-recon
# ═══════════════════════════════════════════════════════════════════════════════

VERSION="1.0"
INTERFAZ=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(en|wl)' | head -n1)

show_help() {
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                  VALENTINO-RECON v$VERSION - Red Team Tool                  ║"
    echo "║                    José Luis Valentino Hernández 2026                       ║"
    echo "╠══════════════════════════════════════════════════════════════════════════════╣"
    echo "║ Uso: sudo valentino-recon --anon <target> [nmap flags]                      ║"
    echo "║ Ej:  sudo valentino-recon --anon scanme.nmap.org                            ║"
    echo "║         sudo valentino-recon --anon 64.13.134.52 -p 22,80,443               ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    exit 0
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
fi

if [ "$1" != "--anon" ]; then
    echo "❌ ERROR: Usa --anon para modo stealth"
    show_help
fi

if [ -z "$2" ]; then
    echo "❌ ERROR: Especifica target"
    show_help
fi

echo "🔥 Iniciando VALENTINO-RECON v$VERSION..."
echo "📡 Interfaz detectada: $INTERFAZ"

# MAC Spoofing
echo "🔄 Cambiando MAC..."
sudo macchanger -r $INTERFAZ 2>/dev/null || echo "⚠️  MAC change failed (normal en VMs)"

# IP Forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Nmap Stealth Scan via Tor+Proxychains
echo "🛡️  Ejecutando scan sigiloso vía Tor..."
proxychains nmap -sS -Pn --disable-arp-ping --source-port $(shuf -i80-443 -n1) "${@:2}"

echo "✅ Scan completado $(date)"
