#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# VALENTINO-RECON v2.0 - Red Team Recon Tool by José Luis Valentino Hernández
# Especialista Ciberseguridad | ISO 27001 | NIST | 20+ años experiencia
# Instalación: chmod +x valentino-recon.sh && sudo mv valentino-recon.sh /usr/local/bin/valentino-recon
# Uso: sudo valentino-recon --anon <target> [nmap flags]
# GitHub: https://github.com/tuusuario/valentino-recon
# ═══════════════════════════════════════════════════════════════════════════════

VERSION="2.0"
INTERFAZ=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(en|wl)' | head -n1)
OUTPUT_DIR="./recon_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                  VALENTINO-RECON v$VERSION - Red Team Tool                  ║"
    echo "║                    José Luis Valentino Hernández 2026                       ║"
    echo "╠══════════════════════════════════════════════════════════════════════════════╣"
    echo "║ Uso: sudo valentino-recon --anon <target> [nmap flags]                      ║"
    echo "║                                                                             ║"
    echo "║ Ejemplos:                                                                   ║"
    echo "║   sudo valentino-recon --anon scanme.nmap.org                               ║"
    echo "║   sudo valentino-recon --anon scanme.nmap.org                               ║"
    echo "║   sudo valentino-recon --anon scanme.nmap.org -p 22,80,443                  ║"
    echo "║   sudo valentino-recon --anon scanme.nmap.org -p-                           ║"
    echo "║                                                                             ║"
    echo "║ Nuevo en v2.0:                                                              ║"
    echo "║   • Resolución DNS automática (dominio → IP)                                ║"
    echo "║   • Verificación de Tor y conectividad                                      ║"
    echo "║   • Guardado automático de resultados con timestamp                         ║"
    echo "║   • Análisis de servicios críticos (MySQL, FTP, correo sin cifrar)         ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    exit 0
}

# Función: Verificar que se ejecuta como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ ERROR: Este script debe ejecutarse como root${NC}"
        echo "   Usa: sudo valentino-recon --anon <target>"
        exit 1
    fi
}

# Función: Resolver dominio a IP (con validación)
resolve_target() {
    local target=$1

    # Si ya es una IP válida, devolverla
    if [[ $target =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${GREEN}✅ Target es IP válida: $target${NC}" >&2
        echo "$target"
        return
    fi

    # Si no, resolver DNS
    echo -e "${YELLOW}🔍 Resolviendo DNS para: $target${NC}" >&2
    RESOLVED_IP=$(dig +short $target 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -1)

    if [ -z "$RESOLVED_IP" ]; then
        echo -e "${RED}❌ No se pudo resolver el dominio: $target${NC}" >&2
        echo "   Verifica el dominio o usa IP directamente" >&2
        exit 1
    fi

    echo -e "${GREEN}✅ Dominio resuelto a: $RESOLVED_IP${NC}" >&2
    echo "$RESOLVED_IP"
}

# Función: Verificar que Tor está corriendo
check_tor() {
    echo -e "${BLUE}🔍 Verificando Tor...${NC}"
    if ! pgrep -x "tor" > /dev/null; then
        echo -e "${YELLOW}⚠️  Tor no está corriendo. Intentando iniciar...${NC}"
        systemctl start tor 2>/dev/null || service tor start 2>/dev/null
        sleep 3
    fi
    
    if pgrep -x "tor" > /dev/null; then
        echo -e "${GREEN}✅ Tor está activo (127.0.0.1:9050)${NC}"
    else
        echo -e "${RED}❌ Tor no está corriendo. Instala Tor: sudo apt install tor${NC}"
        exit 1
    fi
}

# Función: Verificar conectividad a través de Tor
verify_tor_connection() {
    echo -e "${BLUE}🌐 Verificando conectividad vía Tor...${NC}"
    
    # Intentar hasta 3 veces, esperando que Tor responda
    for i in 1 2 3; do
        echo -e "${YELLOW}   Intento $i de 3...${NC}"
        TOR_IP=$(curl --socks5-hostname 127.0.0.1:9050 -s ifconfig.me 2>/dev/null)
        
        if [ -n "$TOR_IP" ]; then
            echo -e "${GREEN}✅ Tor funcionando. IP de salida: $TOR_IP${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}   No respondió, reintentando en 5 segundos...${NC}"
        sleep 5
    done
    
    # Si después de 3 intentos no funciona
    echo -e "${RED}❌ Tor no está funcionando correctamente${NC}"
    echo -e "${RED}   Ejecuta: sudo systemctl restart tor${NC}"
    exit 1
 }

# Función: Analizar y mostrar servicios críticos después del escaneo
analyze_results() {
    local scan_file=$1
    
    if [ ! -f "$scan_file" ]; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}📊 ANÁLISIS DE SERVICIOS CRÍTICOS${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    
    # MySQL expuesto
    if grep -q "3306.*open" "$scan_file" 2>/dev/null; then
        echo -e "${RED}🔴 CRÍTICO: MySQL (3306) expuesto a Internet${NC}"
        echo -e "   → Debe restringirse a redes internas o VPN"
        echo ""
    fi
    
    # FTP sin TLS
    if grep -q "21.*open" "$scan_file" 2>/dev/null; then
        echo -e "${RED}🔴 ALTO: FTP (21) sin cifrar${NC}"
        echo -e "   → Credenciales viajan en texto plano"
        echo -e "   → Recomendación: Migrar a SFTP o FTPS"
        echo ""
    fi
    
    # POP3 sin cifrar
    if grep -q "110.*open" "$scan_file" 2>/dev/null; then
        echo -e "${YELLOW}🟡 MEDIO: POP3 (110) sin cifrar${NC}"
        echo -e "   → Credenciales de correo en texto plano"
        echo ""
    fi
    
    # IMAP sin cifrar
    if grep -q "143.*open" "$scan_file" 2>/dev/null; then
        echo -e "${YELLOW}🟡 MEDIO: IMAP (143) sin cifrar${NC}"
        echo -e "   → Credenciales de correo en texto plano"
        echo ""
    fi
    
    # RPCbind expuesto
    if grep -q "111.*open" "$scan_file" 2>/dev/null; then
        echo -e "${YELLOW}🟡 MEDIO: RPCbind (111) expuesto${NC}"
        echo -e "   → Permite enumeración de servicios RPC"
        echo ""
    fi
    
    # DNS TCP
    if grep -q "53.*open" "$scan_file" 2>/dev/null; then
        echo -e "${YELLOW}🟡 MEDIO: DNS TCP (53) expuesto${NC}"
        echo -e "   → Posible riesgo de transferencia de zona"
        echo ""
    fi
    
    # Servicios seguros (validación positiva)
    if grep -q "993.*open" "$scan_file" 2>/dev/null; then
        echo -e "${GREEN}✅ IMAPS (993) activo - Correo cifrado disponible${NC}"
    fi
    
    if grep -q "995.*open" "$scan_file" 2>/dev/null; then
        echo -e "${GREEN}✅ POP3S (995) activo - Correo cifrado disponible${NC}"
    fi
    
    if grep -q "465.*open" "$scan_file" 2>/dev/null; then
        echo -e "${GREEN}✅ SMTPS (465) activo - Correo saliente cifrado${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📁 Reporte completo guardado en: $scan_file${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
}

# Función principal
main() {
    check_root
    
    if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        show_help
    fi
    
    if [ "$1" != "--anon" ]; then
        echo -e "${RED}❌ ERROR: Usa --anon para modo stealth${NC}"
        show_help
    fi
    
    if [ -z "$2" ]; then
        echo -e "${RED}❌ ERROR: Especifica target${NC}"
        show_help
    fi
    
    TARGET_INPUT="$2"
    shift 2  # Remover --anon y target, dejar el resto para nmap
    NMAP_FLAGS="$@"
    
    # Si no hay flags específicos, usar -p- por defecto (todos los puertos)
    if [ -z "$NMAP_FLAGS" ]; then
        NMAP_FLAGS="-p-"
    fi
    
    echo -e "${GREEN}🔥 Iniciando VALENTINO-RECON v$VERSION...${NC}"
    echo "📡 Interfaz detectada: $INTERFAZ"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # FASE 1: MAC Spoofing
    # ─────────────────────────────────────────────────────────────────────────
    echo -e "${BLUE}🔄 Cambiando MAC en $INTERFAZ...${NC}"
    ip link set $INTERFAZ down 2>/dev/null
    macchanger -r $INTERFAZ 2>/dev/null
    ip link set $INTERFAZ up 2>/dev/null
    echo -e "${GREEN}✅ MAC cambiada${NC}"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # FASE 2: IP Forwarding
    # ─────────────────────────────────────────────────────────────────────────
    echo -e "${BLUE}🔄 Activando IP forwarding...${NC}"
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    echo -e "${GREEN}✅ IP forwarding activado${NC}"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # FASE 3: Verificar Tor
    # ─────────────────────────────────────────────────────────────────────────
    check_tor
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # FASE 4: Verificar conectividad Tor
    # ─────────────────────────────────────────────────────────────────────────
    verify_tor_connection
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # FASE 5: Resolver target (dominio → IP)
    # ─────────────────────────────────────────────────────────────────────────
    TARGET_IP=$(resolve_target "$TARGET_INPUT")
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # FASE 6: Crear directorio de resultados
    # ─────────────────────────────────────────────────────────────────────────
    mkdir -p $OUTPUT_DIR
    OUTPUT_FILE="$OUTPUT_DIR/scan_${TIMESTAMP}_$(echo $TARGET_IP | tr '.' '_')"
    
    # ─────────────────────────────────────────────────────────────────────────
    # FASE 7: Escaneo con Nmap vía proxychains
    # ─────────────────────────────────────────────────────────────────────────
    echo -e "${BLUE}🛡️  Ejecutando scan sigiloso vía Tor...${NC}"
    echo -e "${YELLOW}   Target: $TARGET_IP${NC}"
    echo -e "${YELLOW}   Flags: $NMAP_FLAGS${NC}"
    echo -e "${YELLOW}   Output: $OUTPUT_FILE${NC}"
    echo ""
    
    proxychains nmap -sS -Pn --disable-arp-ping \
        --source-port $(shuf -i80-443 -n1) \
        $NMAP_FLAGS \
        $TARGET_IP \
        -oA "$OUTPUT_FILE"
    
    echo ""
    echo -e "${GREEN}✅ Scan completado $(date)${NC}"
    
    # ─────────────────────────────────────────────────────────────────────────
    # FASE 8: Análisis de resultados
    # ─────────────────────────────────────────────────────────────────────────
    analyze_results "${OUTPUT_FILE}.nmap"
}

# Ejecutar
main "$@"
