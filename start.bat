@echo off
start "Pokemon Showdown Server" cmd /k "cd /d caches\DH2 && node pokemon-showdown"
start "Client HTTP Server" cmd /k "cd /d play.pokemonshowdown.com && python -m http.server 8080"
start "Cloudflare Tunnel" cmd /k "cloudflared tunnel --config config.yml run dh2"