# VitePress + Nginx Docker image

This repository contains a multi-stage Dockerfile that builds a VitePress site (if present) and serves it with nginx.

Quick commands (PowerShell):

Build the Docker image:

```powershell
docker build -t vitepress-nginx .
```

Run the container and expose port 8080:

```powershell
docker run -p 8080:80 --rm vitepress-nginx
```

Open http://localhost:8080

How it works

- Build stage: uses Node 20 (Debian) to install dependencies and run `npm run docs:build` (preferred) or `npm run build` if available.
- The build stage normalizes output into `/app/www` using known VitePress output paths.
- Production stage: `nginx:stable-alpine` serves the static files from `/usr/share/nginx/html` with an SPA-friendly `try_files` fallback.

Notes and troubleshooting

- If your site doesn't appear, check that `app/package.json` contains either a `docs:build` or `build` script.
- VitePress typically places generated files under `app/docs/.vitepress/dist` for the `docs:build` command; the Dockerfile handles this.
- If builds fail with crypto-related errors, we switch to a Debian-based Node build image which resolves common OpenSSL/crypto compatibility issues.

Customize

- To serve a specific directory instead of the detected build output, edit the `Dockerfile` and change the paths copied into the nginx stage.
- To enable gzip or TLS, update `nginx.conf`.

If you want, I can:
- Add gzip, caching, and security headers to `nginx.conf`.
- Add a simple healthcheck to the Dockerfile.
- Tag and push the image to a registry.
