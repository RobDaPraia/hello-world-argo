import os

from flask import Flask, render_template
from werkzeug.middleware.proxy_fix import ProxyFix

__version__ = "1.0.0.0"

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)


@app.route("/health")
def health():
    """Return health status for the readiness probe."""
    return {"status": "ok"}, 200


@app.route("/")
def index():
    """Render the home page."""
    return render_template("index.html", version=__version__)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))

    app.run(host="0.0.0.0", port=port)
