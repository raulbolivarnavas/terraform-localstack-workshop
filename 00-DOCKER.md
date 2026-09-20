# Instalando Docker en Ubuntu (WSL2)

Dado que WSL2 (Windows Subsystem for Linux 2) permite ejecutar un entorno Linux completo en Windows, es posible instalar y configurar Docker para gestionar contenedores de manera eficiente. A continuación, se detallan los pasos para instalar Docker en Ubuntu dentro de WSL2.

---

1. Abre una terminal de Ubuntu en WSL2.

```bash
sudo apt update
sudo apt install -y docker.io
```

---

2. Habilita y inicia el servicio de Docker:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

---

3. Agrega tu usuario al grupo de Docker para evitar usar `sudo` cada vez que ejecutes comandos de Docker:

```bash
sudo usermod -aG docker $USER
```

---

4. Cierra la sesión y vuelve a iniciarla para que los cambios surtan efecto.

---
