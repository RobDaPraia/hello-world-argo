# https://ryxcommar.com/2024/02/15/how-to-cut-your-python-docker-builds-in-half-with-uv/
# https://docs.astral.sh/uv/guides/integration/docker/#using-uv-in-docker

FROM python:3.13-slim

# https://wbarillon.medium.com/docker-python-image-with-psycopg2-installed-c10afa228016
RUN apt-get update && \
    apt-get install -y libpq-dev gcc

# Update system packages to reduce vulnerabilities
#RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Compile bytecode
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#compiling-bytecode
ENV UV_COMPILE_BYTECODE=1

WORKDIR /app

# Copy project files from repository root
COPY pyproject.toml uv.lock /app/
COPY src/ /app/src/

RUN uv sync --frozen --no-cache

# Display the project's dependency tree
# Run 'docker build --progress=plain --no-cache -t gahhelloworld .' to see the output
# https://github.com/astral-sh/uv/issues/8342
#RUN ls -lah /app/.venv/bin

WORKDIR /app/src/argo-web

#CMD ["uv", "run", "app/main.py", "--port", "5000"]
#CMD ["uv", "run", "app/main.py"]
CMD ["uv", "run", "gunicorn", "--config", "gunicorn.conf.py", "wsgi:application"]


#
# To build the Docker file from the repository root, run the following command:
# docker build --no-cache -t argoweb:v1.0 -f src/argo-web/Dockerfile .
#
# To run the Docker container with .env, run the following command:
# docker run -e PORT=5000 -p 5000:5000 --name argoweb --rm argoweb:v1.0 
#
# Open the browser and navigate to http://localhost:5000

