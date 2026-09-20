# Instalando LocalStack en WSL2

Dado que LocalStack es una herramienta que simula servicios de AWS en tu máquina local, es útil para desarrollo y pruebas sin necesidad de interactuar con la nube real. A continuación, se detallan los pasos para instalar LocalStack en un entorno WSL2 (Windows Subsystem for Linux 2).
Es necesario obtener un token de LocalStack para poder utilizarlo. Puedes obtenerlo registrándote en el sitio web oficial de LocalStack y siguiendo las instrucciones para generar un token.

---

1. Instalar Ubuntu desde Microsoft Store.

---

2. Abre una terminal de Ubuntu.

---

3. Actualiza los paquetes del sistema:

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

---

4. Instala Docker si aún no lo tienes instalado:

   ```bash
   sudo apt install docker.io -y
   ```

---

5. Habilita y inicia el servicio de Docker:

   ```bash
   sudo systemctl enable docker
   sudo systemctl start docker
   ```

---

6. Agrega tu usuario al grupo de Docker para evitar usar `sudo` cada vez que ejecutes comandos de Docker:

   ```bash
   sudo usermod -aG docker $USER
   ```

---

7. Cierra la sesión y vuelve a iniciarla para que los cambios surtan efecto.

---

8. Verifica que Docker esté funcionando correctamente:

   ```bash
   docker --version
   ```

---

9. Instala Docker Compose si aún no lo tienes instalado:

   ```bash
   sudo apt install docker-compose -y
   ```

---

10. Instala LocalStack usando Docker Compose. utilizando el archivo `docker/docker-compose.yml`:

   ```bash
   sudo docker compose up -d
   ```

---

11. Verifica que LocalStack esté corriendo:

   ```bash
   docker ps
   ```

---

12. Para detener LocalStack, puedes usar el siguiente comando:

   ```bash
   curl http://localhost:4566/_localstack/health
   ```

---

13. Instala Terraform:

   ```bash
   # Agregamos el repositorio de HashiCorp para instalar Terraform
   sudo apt-get update
   sudo apt-get install -y gnupg software-properties-common curl
   
   # Agregamos la clave GPG del repositorio de HashiCorp
   curl -4 -fsSL https://apt.releases.hashicorp.com/gpg \
      -o /tmp/hashicorp.asc
      
   # Convertimos la clave GPG a un formato compatible con apt
   sudo gpg --dearmor \
      --output /usr/share/keyrings/hashicorp-archive-keyring.gpg \
      /tmp/hashicorp.asc
      
   # Verificamos la clave GPG
   gpg \
      --no-default-keyring \
      --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
      --fingerprint
      
   # Agregamos el repositorio de HashiCorp a la lista de fuentes de apt
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
      | sudo tee /etc/apt/sources.list.d/hashicorp.list
   
   # Actualizamos la lista de paquetes e instalamos Terraform
   sudo apt update
   apt-cache policy terraform
   
   # Instalamos Terraform
   sudo apt install -y terraform
   
   # Verificamos la instalación de Terraform
   terraform --version
   
   # Creamos una carpeta para almacenar los archivos de Terraform
   mkdir -p terraform 
   ```
   
---

14. Estando en la carpeta `terraform` ejecutemos los siguientes comandos para inicializar Terraform:

   ```bash
   # Inicializamos Terraform en la carpeta terraform
   terraform init

   # Formateamos el código de Terraform
   terraform fmt -recursive
   
   # Validamos la configuración de Terraform
   terraform validate
   
   # Ejecutamos un plan de Terraform para ver los cambios que se aplicarán
   terraform plan   
   
   # Aplicamos los cambios de Terraform para crear la infraestructura
   terraform apply
   ```

---

15. Eliminar toda la infraestructura creada por Terraform:

   ```bash
   # Eliminamos toda la infraestructura creada por Terraform
   terraform destroy
   ```

---
