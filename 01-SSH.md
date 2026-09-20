# Instalando SSH en Ubuntu (WSL2)

Dado que WSL2 (Windows Subsystem for Linux 2) permite ejecutar un entorno Linux completo en Windows, es posible instalar y configurar un servidor SSH para acceder a tu instancia de Ubuntu desde otros dispositivos o incluso desde la misma máquina. A continuación, se detallan los pasos para instalar y configurar SSH en Ubuntu dentro de WSL2.

---

1. Abre una terminal de Ubuntu en WSL2.

```bash
sudo apt update
sudo apt install -y openssh-server
```

---

2. Habilita y inicia el servicio SSH:

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

---