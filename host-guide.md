# DH2 Host Guide

How to set up, run, and publicly host the DH2 client and server on `pokemon.mochilicius.com` and `pokemon-backend.mochilicius.com`.

---

## 1. Initial Setup

### Fork the repositories

1. Fork [scoopapa/dh2-client](https://github.com/scoopapa/dh2-client) to your GitHub profile
2. Fork [scoopapa/DH2](https://github.com/scoopapa/DH2) to your GitHub profile

### Clone and configure

3. Git clone your `dh2-client` fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/dh2-client
   cd dh2-client
   ```

4. Edit `build-tools/server-repo` — replace `scoopapa/DH2.git` with your own fork URL:
   ```
   https://github.com/YOUR_USERNAME/DH2
   ```

5. Edit `config/config.js` so that `Config.defaultserver` looks like this:
   ```js
   Config.defaultserver = {
       id: 'dragonheaven',
       host: 'localhost',
       port: 8000,
       httpport: 8000,
       altport: 80,
       registered: true
   };
   ```
   If there is no config file at `play.pokemonshowdown.com/config/`, copy `config/config.js` there manually.

6. Prevent these files from being accidentally committed:
   ```bash
   git update-index --skip-worktree ./config/config.js
   git update-index --skip-worktree ./build-tools/server-repo
   ```

---

## 2. Building and Running Locally

### Build

From the `dh2-client` directory, run:
```bash
node build full
```
This may take a few minutes. Wait for it to complete fully before continuing.

### Start the server

The build outputs a ready-to-run server inside `caches/DH2/`. Start it with:
```bash
cd caches/DH2
node pokemon-showdown
```
The server runs on port `8000` by default.

### Use the client locally

Open this path in your browser (adjust for your own machine):
```
D:/Sean/Documents/Projects/dh2-client/play.pokemonshowdown.com/testclient.html
```

To connect it to your locally running server, append `?~~localhost:8000`:
```
D:/Sean/Documents/Projects/dh2-client/play.pokemonshowdown.com/testclient.html?~~localhost:8000
```

---

## 3. Serving the Client via HTTP (Required for Domain Hosting)

The client needs to be served over HTTP rather than as a local file when attaching a domain. Use any simple static file server pointed at the `play.pokemonshowdown.com/` directory.

**Using Python (quickest option):**
```bash
cd play.pokemonshowdown.com
python -m http.server 8080
```

**Using Node (if you prefer):**
```bash
npx serve play.pokemonshowdown.com -p 8080
```

The client will then be accessible at `http://localhost:8080`.

> **Note:** Before hosting publicly, update `config/config.js` so the client connects to your public backend domain instead of localhost. Change `Config.defaultserver` to:
> ```js
> Config.defaultserver = {
>     id: 'dragonheaven',
>     host: 'pokemon-backend.mochilicius.com',
>     port: 443,
>     httpport: 443,
>     altport: 443,
>     registered: true
> };
> ```
> Then rebuild (`node build full`) so the changes are picked up. Keep a separate local config for development.

---

## 4. Hosting with Cloudflare Tunnel (cloudflared)

Cloudflare Tunnel lets you expose local services to your domain without opening ports or a VPS. Traffic flows: `browser → Cloudflare → cloudflared (on your machine) → local service`.

### Install cloudflared

Download from [https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) and install it.

Or run 
```bash
winget install --id Cloudflare.cloudflared 
```


On Windows, place `cloudflared.exe` somewhere in your PATH, or run it from its directory.

### Authenticate

```bash
cloudflared tunnel login
```
This opens a browser window. Log in to your Cloudflare account and authorise access to `mochilicius.com`. A credentials file is saved automatically.

### Create a tunnel

```bash
cloudflared tunnel create dh2
```
Note the tunnel ID printed (e.g. `abc123...`). You'll need it below.

"Tunnel credentials written to C:\Users\3853827\.cloudflared\46ab6d43-13e2-4b2c-ab83-f96d9d4e7d08.json. cloudflared chose this file based on where your origin certificate was found. Keep this file secret. To revoke these credentials, delete the tunnel.

Created tunnel dh2 with id 46ab6d43-13e2-4b2c-ab83-f96d9d4e7d08
2026-03-20T14:58:38Z WRN Your version 2025.8.1 is outdated. We recommend upgrading it to 2026.3.0"

### Configure the tunnel

Create a config file at `config.yml` in the dh2-client root:

```yaml
tunnel: dh2
credentials-file: C:\Users\YOUR_USERNAME\.cloudflared\TUNNEL_ID.json

ingress:
  - hostname: pokemon.mochilicius.com
    service: http://localhost:8080
  - hostname: pokemon-backend.mochilicius.com
    service: http://localhost:8000
  - service: http_status:404
```

Replace `YOUR_USERNAME` with your actual Windows username, and `TUNNEL_ID` with the UUID printed when you ran `cloudflared tunnel create` (e.g. `46ab6d43-...`).

### Create DNS records

Run these to automatically create the CNAME records in Cloudflare:
```bash
cloudflared tunnel route dns dh2 pokemon.mochilicius.com
cloudflared tunnel route dns dh2 pokemon-backend.mochilicius.com
```

### Start the tunnel

```bash
cloudflared tunnel --config config.yml run dh2
```

### Start everything at once

Instead of running each command manually, use the included batch script from the dh2-client root:

```bash
.\start.bat
```

This opens 3 separate terminal windows for each service with labeled titles.

With both the server (`node pokemon-showdown`), client server (`python -m http.server 8080`), and tunnel running, your services will be live at:
- Client: `https://pokemon.mochilicius.com`
- Server: `https://pokemon-backend.mochilicius.com`

---

## 5. Run cloudflared as a Windows Service (Optional)

To have the tunnel start automatically with Windows instead of running it manually each time:

```bash
cloudflared service install
```

Then start it:
```bash
sc start cloudflared
```

To stop or uninstall:
```bash
sc stop cloudflared
cloudflared service uninstall
```

> The service uses the config at `C:\Windows\System32\config\systemprofile\.cloudflared\config.yml` when running as a system service. Copy your config there, or use `cloudflared --config C:\path\to\config.yml service install` to specify the path explicitly.

---

## 6. Committing Server Changes

After making changes, commit from the `caches/DH2` directory (your DH2 fork), not from `dh2-client`:

```bash
cd caches/DH2
git add .
git commit -m "your message"
git push
```

Changes to the client code are committed from the `dh2-client` root as normal.
