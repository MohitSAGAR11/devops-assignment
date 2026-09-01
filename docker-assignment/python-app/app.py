import socket
from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello():
    return f"""<!doctype html>
<html>
  <head><title>Python Hello World</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding: 60px;">
    <h1>Hello World</h1>
    <p>Served by <strong>Python + Flask</strong> inside Docker</p>
    <p>Hostname (container id): {socket.gethostname()}</p>
  </body>
</html>"""


@app.route("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
