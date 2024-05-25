########################### GENERACION DE PKI Y CERTIFICADOS
FROM ubuntu:jammy AS easyrsa-certs

USER root
RUN apt update && apt install easy-rsa -y

# generar certificados y claves para nuestro PKI, incluyendo el del CA, el servidor Docker
# y un cliente
WORKDIR /usr/share/easy-rsa
RUN ./easyrsa init-pki && mkdir pki/temp/

# archivos con el nombre del servidor y del cliente, que irá en el campo CN del 
# certificado correspondiente
COPY nombre_servidor.txt .
COPY nombre_cliente.txt .
# archivo con parametros para la personalizacion del certificado del CA
COPY vars .

# script para la generacion de certificados y claves privadas de nuestra PKI, necesaria
# para que Docker use TLS
COPY script_creacion_pki.sh .
RUN chmod u+x script_creacion_pki.sh && ./script_creacion_pki.sh


########################### UBUNTU CON DOCKER INSTALADO
# aun no hay version de docker estable para Ubuntu 23.10 ni para 24.04, asi que usamos
# la version Jammy Jellyfish, 22.04
FROM ubuntu:jammy

ENTRYPOINT ["dockerd"]

USER root
RUN apt update && apt install openssh-server curl -y

# script para la instalacion de docker
WORKDIR /root
COPY script_instalacion_docker.sh .
RUN chmod u+x script_instalacion_docker.sh
RUN sh -c ./script_instalacion_docker.sh

# generar claves SSH con la passphrase introducida por el creador de la imagen, se
# recomienda cambiar esta passphrase en el archivo "passphrase_clave_ssh.txt" y volver 
# a construir la imagen
COPY passphrase_clave_ssh.txt .
RUN mkdir .ssh && \
	ssh-keygen -t rsa -C servidor@tfg.canaveral -N `cat passphrase_clave_ssh.txt` \
	-f .ssh/clave_rsa && \
	rm passphrase_clave_ssh.txt

# obtener certificados de la stage easyrsa-certs
# certificados del CA
RUN mkdir /certs

WORKDIR /certs/ca
COPY --from=easyrsa-certs /usr/share/easy-rsa/pki/ca/* .

# certificados del servidor
WORKDIR /certs/servidor
COPY nombre_servidor.txt .
COPY --from=easyrsa-certs /usr/share/easy-rsa/pki/servidor/* .

# certificados del cliente
WORKDIR /certs/cliente
COPY nombre_cliente.txt .
COPY --from=easyrsa-certs /usr/share/easy-rsa/pki/cliente/* .
COPY --from=easyrsa-certs /usr/share/easy-rsa/pki/ca/* .

RUN chmod 600 /certs/servidor/key.pem
RUN chmod 644 /certs/ca/ca.pem /certs/cliente/ca.pem /certs/servidor/cert.pem /certs/cliente/cert.pem /certs/cliente/key.pem

WORKDIR /
# este archivo se utiliza simplemente como punto de partida para la configuracion de 
# docker pero si se edita el fichero daemon.json y se usa docker compose para levantar el 
# contenedor el original de la imagen se sobreescribe
COPY daemon.json /etc/docker/daemon.json
