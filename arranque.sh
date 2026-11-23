#!/bin/bash
# Máquina de aplicación: una página que en cada visita le pide a Redis,
# en la máquina de datos, que sume uno al contador. Si Redis no responde,
# la página no se sirve: devuelve 503.
INTERNA=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

mkdir -p /opt/app
cat > /opt/app/app.py <<'PY'
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

IP_DATOS = "${ip_datos}"
INTERNA = os.environ.get("INTERNA", "?")


def contar_visita():
    # INCR en el protocolo de Redis, sin librerías: la respuesta es ":<n>".
    with socket.create_connection((IP_DATOS, 6379), timeout=3) as conexion:
        conexion.sendall(b"*2\r\n$4\r\nINCR\r\n$7\r\nvisitas\r\n")
        respuesta = conexion.recv(64).decode()
    if not respuesta.startswith(":"):
        raise RuntimeError(respuesta.strip())
    return int(respuesta[1:])


class Pagina(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/":
            self.responder(404, "<p>No existe.</p>")
            return
        try:
            visitas = contar_visita()
        except Exception as error:
            self.responder(503, f"<h1>Grupo 2</h1><p>La máquina de datos ({IP_DATOS}) no responde: {error}</p>")
            return
        self.responder(200, (
            "<h1>Grupo 2 · 1152370 · 1152355</h1>"
            f"<p>Servidor de aplicación. IP interna: {INTERNA}</p>"
            f"<p>Visitas: <strong>{visitas}</strong>, contadas por Redis en la máquina de datos ({IP_DATOS}).</p>"
        ))

    def responder(self, codigo, cuerpo):
        pagina = f'<!doctype html><meta charset="utf-8"><title>Grupo 2</title>{cuerpo}'.encode()
        self.send_response(codigo)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(pagina)))
        self.end_headers()
        self.wfile.write(pagina)


ThreadingHTTPServer(("", 80), Pagina).serve_forever()
PY

cat > /etc/systemd/system/app.service <<UNIT
[Unit]
Description=Pagina del grupo 2
After=network-online.target

[Service]
Environment=INTERNA=$INTERNA
ExecStart=/usr/bin/python3 /opt/app/app.py
DynamicUser=yes
AmbientCapabilities=CAP_NET_BIND_SERVICE
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now app.service
