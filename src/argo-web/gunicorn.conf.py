"""Gunicorn configuration file for Flask app."""

import os

# Server socket - use PORT env variable or default to 5000
port = os.environ.get("PORT", "5000")
bind = f"0.0.0.0:{port}"
backlog = 2048

# Worker processes
workers = 4
worker_class = "sync"
worker_connections = 1000
timeout = 120
keepalive = 2

# Restart workers after this many requests, to help prevent memory leaks
max_requests = 1000
max_requests_jitter = 100

# Logging
loglevel = "info"
accesslog = "-"  # Log to stdout
errorlog = "-"  # Log to stderr
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "geminisample-flask"

# Server mechanics
daemon = False
pidfile = None
user = None
group = None
tmp_upload_dir = None

# SSL (if needed in the future)
# keyfile = None
# certfile = None

# Environment variables can override these settings
if os.getenv("GUNICORN_WORKERS"):
    workers = int(os.getenv("GUNICORN_WORKERS"))

if os.getenv("GUNICORN_TIMEOUT"):
    timeout = int(os.getenv("GUNICORN_TIMEOUT"))

if os.getenv("GUNICORN_BIND"):
    bind = os.getenv("GUNICORN_BIND")
