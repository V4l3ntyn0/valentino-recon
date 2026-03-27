# 🔥 VALENTINO-RECON

**Herramienta de reconocimiento sigiloso con anonimato para auditorías de ciberseguridad**

Desarrollada por **José Luis Valentino Hernández**  
Especialista en Ciberseguridad | ISO 27001 | NIST | 20+ años de experiencia

---

## 📌 Características

- ✅ **MAC Spoofing automático** - Cambia tu dirección MAC antes de cada escaneo
- ✅ **Anonimato con Tor** - Todo el tráfico enrutado a través de la red Tor
- ✅ **Resolución DNS automática** - Convierte dominios a IP automáticamente
- ✅ **Verificación de Tor** - Confirma conectividad antes de escanear (con reintentos)
- ✅ **Guardado automático** - Resultados con timestamp en `./recon_results/`
- ✅ **Análisis de servicios críticos** - Detecta MySQL expuesto, FTP sin TLS, etc.
- ✅ **Soporte para flags de Nmap** - Compatible con todos los parámetros de Nmap

---

## 📧 Solicitud de uso

Esta herramienta es de **uso personal y educativo**.  
Para solicitar permiso de uso, colaboración o licencia comercial, contactar a:  
**jlvhdp@gmail.com**

Ver archivo [LICENSE](LICENSE) para más información.

---

## 🚀 Instalación

```bash
git clone https://github.com/V4l3ntyn0/valentino-recon.git
cd valentino-recon
chmod +x valentino-recon.sh
sudo cp valentino-recon.sh /usr/local/bin/valentino-recon

# Dependencias
sudo apt update
sudo apt install tor proxychains macchanger nmap -y
sudo systemctl enable --now tor
