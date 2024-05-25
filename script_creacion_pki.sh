#!/bin/sh

export NOMBRE_SERVIDOR=`cat nombre_servidor.txt`
export NOMBRE_CLIENTE=`cat nombre_cliente.txt`

# crear certificado para el CA y almacenarlo en una ruta dedicada para él
echo $NOMBRE_SERVIDOR | ./easyrsa build-ca nopass && mkdir pki/ca/ && \
        cp pki/ca.crt pki/ca/ca.pem

# generar certificado y clave para el servidor
./easyrsa build-server-full $NOMBRE_SERVIDOR nopass && mkdir pki/servidor/ && \
	cp pki/issued/${NOMBRE_SERVIDOR}.crt pki/servidor/cert.pem && \
	cp pki/private/${NOMBRE_SERVIDOR}.key pki/servidor/key.pem

# generar certificado y clave para el cliente
./easyrsa build-client-full $NOMBRE_CLIENTE nopass && mkdir pki/cliente/ && \
	cp pki/issued/${NOMBRE_CLIENTE}.crt pki/cliente/cert.pem && \
	cp pki/private/${NOMBRE_CLIENTE}.key pki/cliente/key.pem
