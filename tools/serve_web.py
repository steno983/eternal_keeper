"""Serve the exported demo to this computer and phones on the same Wi-Fi."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import socket
parser=argparse.ArgumentParser()
parser.add_argument('--port',type=int,default=8765)
parser.add_argument('--host',default='0.0.0.0')
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]/'build/web'
if not (root/'index.html').is_file(): raise SystemExit('Esporta prima la demo Web.')
class Handler(SimpleHTTPRequestHandler):
 def end_headers(self):
  self.send_header('Cache-Control','no-cache')
  super().end_headers()
 def log_message(self,*args): pass
addresses=sorted({item[4][0] for item in socket.getaddrinfo(socket.gethostname(),None,socket.AF_INET)})
print(f'Demo locale: http://localhost:{args.port}',flush=True)
for address in addresses:
 if not address.startswith('127.'): print(f'Telefono sulla stessa Wi-Fi: http://{address}:{args.port}',flush=True)
try: ThreadingHTTPServer((args.host,args.port),partial(Handler,directory=str(root))).serve_forever()
except KeyboardInterrupt: pass
