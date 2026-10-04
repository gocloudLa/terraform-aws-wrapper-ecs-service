import functools
import http.server

handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory="/opt/app/static")
http.server.ThreadingHTTPServer(("0.0.0.0", 8080), handler).serve_forever()
