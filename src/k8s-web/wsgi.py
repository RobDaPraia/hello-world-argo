"""WSGI entry point for Gunicorn to serve the Flask application.

This module ensures proper path setup for Gunicorn deployment.
"""

import sys
import os

# Set up the Python path before importing any local modules
# This must happen before any local imports
current_dir = os.path.dirname(os.path.abspath(__file__))

# Add the flaskapp directory to the Python path for local imports
# This allows imports like 'from app.main import app'
flaskapp_path = os.path.dirname(current_dir)  # /app/src
sys.path.insert(0, os.path.abspath(flaskapp_path))

# Add the flaskapp/app directory to the Python path for the 'common' module
flaskapp_app_path = os.path.join(current_dir, "app")  # /app/src/k8s-web/app
sys.path.insert(0, os.path.abspath(flaskapp_app_path))

# Now we can import the Flask app
from app.main import app  # noqa

# Export the app for Gunicorn
application = app

if __name__ == "__main__":
    # This allows the file to be run directly for testing
    app.run(host="0.0.0.0", port=5000, debug=False)
