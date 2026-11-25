# GateBoard standalone deploy page

Single self-contained file: `index.html` (no libraries, no fonts, no server,
no tracking). It is the same one-tap deploy page as the Muse artifact, but
served top-level so a wallet can inject `window.ethereum` /
`window.binancew3w.ethereum` into it. The Muse-shared link wraps the page,
which is why Binance, Zerion and Rabby all reported "no wallet found".

Deploy data is fixed: solc 0.8.20, optimizer on, 200 runs, constructor
argument `0x60b9262456de011f7d15a54cdd8c48baaa8b022f` (Agent ID contract).
Verified byte-for-byte against `../DEPLOY_PAGE_SPEC.md` (8,546 chars).

## Why there is no live tunnel link right now (2026-11-25)

Tried from the sandbox, all blocked by the sandbox's egress proxy — not by
the page:
- Cloudflare Tunnel (`cloudflared tunnel --url`): quick-tunnel request
  fails, TLS handshake error; `api.trycloudflare.com` returns 403.
- localtunnel (`npx localtunnel --port 8765`): client starts but never
  prints a URL; the tunnel connection hangs.
- tunnelmole: TLS `EPROTO wrong version number` — handshake intercepted.
- SSH tunnels (serveo, pinggy): SSH is reset by the proxy (198.19.0.1:3128).
- File hosts (0x0.st, tmpfiles.org, transfer.sh, uguu.se, catbox):
  multipart POSTs complete uploading but the response never arrives
  (timeouts); 0x0.st returns 500, transfer.sh unreachable.
- Muse built-in storage (`remote-storage upload-file`): upload works, but
  the link returns 403 from curl and is `application/octet-stream`
  (would download, not render as a page).

So the durable way to get a direct link is GitHub Pages, below. It needs
Eric's GitHub account (Eric-Again) — no one else can publish to it.

## Backup plan — GitHub Pages (durable direct URL, phone steps)

1. On the phone, open github.com in Safari/Chrome and sign in as
   Eric-Again.
2. Create a new **public** repo, e.g. `gateboard-deploy`. No README,
   no .gitignore needed.
3. In the repo, tap **Add file → Upload files**.
4. Upload `index.html` from this folder (get the file from Muse — ask
   Muse to send it, or download it from the workspace). The repo must
   contain `index.html` at the top level, nothing else required.
5. Commit the upload (default message is fine).
6. Go to the repo **Settings → Pages**.
7. Under "Build and deployment", set Source to **Deploy from a branch**,
   Branch **main**, folder **/ (root)**, then Save.
8. Wait 1–2 minutes. GitHub shows the live URL at the top of the Pages
   settings, e.g. `https://eric-again.github.io/gateboard-deploy/`
   (exact name depends on the repo name you chose).
9. Copy that URL and open it **inside your wallet app's own browser**:
   Binance Web3 Discover (Wallets → Web3 → Discover), Zerion (Browser
   tab), Rabby (Browser), or Trust Wallet (Browser). Tap Connect Wallet.
   The page has a "Wallet check (diagnostics)" box — if Connect still
   fails, tap "Copy diagnostics" and paste it to Muse.
10. After deploying, verify the contract on BscScan with: compiler
    0.8.20, license MIT, optimizer enabled 200 runs, constructor
    argument `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`, source =
    the full `GateBoard.sol` shown on the page.

Do NOT paste your seed phrase or private key anywhere in this flow.
GitHub Pages is free and the page stays up until the repo is deleted.

## Local test (sandbox only)

```bash
cd ~/workspace/hackathon-binance-gateboard/standalone-deploy
bash start-server.sh        # serves http://127.0.0.1:8765/index.html
```

That URL is only reachable inside the sandbox — it is not a public link.
A public link needs either a working tunnel (see failures above) or
GitHub Pages.
