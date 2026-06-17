
```markdown
<p align="center">
  <img src="https://img.shields.io/badge/bash-5.0%2B-blue?logo=gnubash&logoColor=white" alt="Bash 5.0+">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/version-1.0-orange" alt="Version">
</p>

<h1 align="center">
  <br>
  mke-ffuf
  <br>
</h1>

<h4 align="center">A focused, zero-dependency web fuzzer built entirely in Bash.</h4>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-target-modes">Target Modes</a> •
  <a href="#-examples">Examples</a> •
  <a href="#-how-it-works">How It Works</a> •
  <a href="#-faq">FAQ</a>
</p>

---

```
  ███╗   ███╗██╗  ██╗███████╗      ███████╗███████╗██╗   ██╗███████╗
  ████╗ ████║██║ ██╔╝██╔════╝      ██╔════╝██╔════╝██║   ██║██╔════╝
  ██╔████╔██║█████╔╝ █████╗  █████╗█████╗  █████╗  ██║   ██║█████╗
  ██║╚██╔╝██║██╔═██╗ ██╔══╝  ╚════╝██╔══╝  ██╔══╝  ██║   ██║██╔══╝
  ██║ ╚═╝ ██║██║  ██╗███████╗      ██║     ██║      ╚██████╔╝██║
  ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝      ╚═╝     ╚═╝       ╚═════╝ ╚═╝
```

## 🤔 What is mke-ffuf?

**mke-ffuf** is a lightweight web fuzzer that discovers hidden files, directories, and endpoints on web servers. Think of it as knocking on every door of a building to see which ones open — except the building is a website and the doors are URLs.

Unlike general-purpose fuzzers, mke-ffuf ships with **built-in wordlists tailored to specific frameworks** (WordPress, Laravel, Django, etc.), so you can start fuzzing immediately without downloading anything extra.

**No Go. No Python. No pip. Just Bash and curl.**

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎯 **8 Target Modes** | Built-in wordlists for WordPress, Drupal, Joomla, Laravel, Django, ASP.NET, APIs, and a Generic catch-all |
| 🧠 **Smart 404 Detection** | 3-sample baseline measurement catches custom "Not Found" pages that return HTTP 200 |
| 🔀 **User-Agent Rotation** | Rotates through 5 realistic browser UAs to avoid WAF fingerprinting |
| ⚡ **Threaded Scanning** | Concurrent requests with configurable thread count (default: 20) |
| 🎛️ **Match / Filter Codes** | `-mc 200,301` to show only specific codes, or `-fc 403,500` to hide them |
| 🌐 **Proxy Support** | Route traffic through Burp Suite, ZAP, or any HTTP proxy with `-x` |
| 📁 **File Output** | Save clean results (no color codes) to a file with `-o` |
| 🔒 **TLS Control** | Skip certificate verification with `-k` for self-signed targets |
| 🐌 **Rate Limiting** | Throttle requests per second with `-r` to stay under WAF radar |
| 📦 **SecLists Auto-Merge** | Automatically merges SecLists wordlists if installed, with deduplication |
| 🧹 **Clean Interrupts** | Ctrl+C cleans up all temp files and background jobs gracefully |

---

## 📦 Installation

### One-liner install

```bash
git clone https://github.com/RadhakrishnanSA/mke-ffuf.git
cd mke-ffuf
chmod +x mke-ffuf.sh
sudo ln -s "$(pwd)/mke-ffuf.sh" /usr/local/bin/mke-ffuf
```

### Requirements

| Dependency | Usually pre-installed? | Install if missing |
|---|---|---|
| `bash` 5.0+ | ✅ Yes | — |
| `curl` | ✅ Yes | `sudo apt install curl` |
| `flock` | ✅ Yes (Linux) | `sudo apt install util-linux` |

> **Note:** macOS users may need to install `flock` via Homebrew: `brew install flock`

### Optional: SecLists (recommended)

If [SecLists](https://github.com/danielmiessler/SecLists) is installed at `/usr/share/seclists`, mke-ffuf will automatically merge relevant wordlists with its built-in ones for deeper coverage.

```bash
sudo apt install seclists
# or
git clone https://github.com/danielmiessler/SecLists.git /usr/share/seclists
```

---

## 🚀 Quick Start

```bash
# Basic scan — you'll be prompted to pick a target type
mke-ffuf -u https://example.com

# WordPress site? Pick option 1 when prompted
mke-ffuf -u https://myblog.com

# API endpoint with output saved to file
mke-ffuf -u https://api.target.com -o results.txt
```

**That's it.** No wordlist downloads, no config files, no dependencies to install.

---

## 📖 Usage

```
Usage: mke-ffuf -u <URL> [options]

  -u   Target URL              (required)
  -t   Threads                 [default: 20]
  -T   Timeout seconds         [default: 8]
  -r   Rate limit req/sec      [default: unlimited]
  -w   Custom wordlist file
  -o   Output file             (plain text, no color codes)
  -x   Proxy                   e.g. http://127.0.0.1:8080
  -mc  Match codes             e.g. 200,301
  -fc  Filter codes            e.g. 403,500
  -k   Skip TLS verification
  -h   Show help
```

### Flags Explained

#### `-u` — Target URL *(required)*

The website you want to scan. If you omit `https://`, it's added automatically.

```bash
mke-ffuf -u https://target.com
mke-ffuf -u target.com              # same thing — https:// is added
```

#### `-t` — Threads

How many requests to send at the same time. Higher = faster, but may trigger rate limits.

```bash
mke-ffuf -u target.com -t 10      # slower, gentler
mke-ffuf -u target.com -t 50      # faster, aggressive
```

#### `-T` — Timeout

How long (in seconds) to wait for each request before giving up.

```bash
mke-ffuf -u slow-server.com -T 15   # patient — 15 second timeout
```

#### `-r` — Rate Limit

Maximum requests per second. Use this to avoid getting blocked by WAFs or rate limiters.

```bash
mke-ffuf -u target.com -r 5        # max 5 requests per second
```

#### `-w` — Custom Wordlist

Bring your own wordlist file. When you use `-w`, a 9th option "Custom" appears in the target type menu.

```bash
mke-ffuf -u target.com -w /path/to/my-wordlist.txt
```

Your wordlist should be a plain text file with one path per line:

```
admin
login
api/v1/users
.env
backup.sql
```

#### `-o` — Output File

Save results to a file. The output is clean plain text (no ANSI color codes) so it's easy to parse.

```bash
mke-ffuf -u target.com -o results.txt
```

Output format:

```
[200] [1234b] https://target.com/admin
[301] [0b] https://target.com/login  -> https://target.com/login/
[403] [287b] https://target.com/.env
```

#### `-x` — Proxy

Route all traffic through an HTTP proxy. Essential for inspecting requests in Burp Suite or OWASP ZAP.

```bash
mke-ffuf -u target.com -x http://127.0.0.1:8080       # Burp Suite
mke-ffuf -u target.com -x http://127.0.0.1:8090       # ZAP
```

#### `-mc` — Match Codes

**Only show** responses with these HTTP status codes. Everything else is hidden.

```bash
mke-ffuf -u target.com -mc 200            # only show 200 OK
mke-ffuf -u target.com -mc 200,301,403    # show 200, 301, and 403
```

#### `-fc` — Filter Codes

**Hide** responses with these HTTP status codes. Everything else is shown.

```bash
mke-ffuf -u target.com -fc 403            # hide all 403s
mke-ffuf -u target.com -fc 301,302,403    # hide redirects and 403s
```

> **Note:** If you use both `-mc` and `-fc` together, `-mc` takes priority. Only codes in the `-mc` list will be shown, regardless of `-fc`.

#### `-k` — Skip TLS Verification

Disable SSL/TLS certificate checks. Useful for targets with self-signed or expired certificates.

```bash
mke-ffuf -u https://internal-server.local -k
```

> A warning `[!] TLS verification disabled` is shown in the scan header when this is active.

---

## 🎯 Target Modes

When you run mke-ffuf, you'll see this menu:

```
Select target type:

  1  WordPress
  2  Drupal
  3  Joomla
  4  Laravel
  5  Django
  6  ASP.NET / IIS
  7  API / REST / GraphQL
  8  Generic
  9  Custom (/path/to/wordlist.txt)    ← only if -w is used
```

Pick the one that matches your target. Each mode uses a **curated wordlist** designed for that specific technology.

### 1 — WordPress

Targets WordPress-specific paths like `wp-login.php`, `wp-admin/`, `wp-json/wp/v2/users`, `xmlrpc.php`, `wp-content/debug.log`, and more. Ideal for WordPress recon.

### 2 — Drupal

Covers Drupal paths: `user/login`, `admin/config`, `sites/default/settings.php`, `CHANGELOG.txt`, `update.php`, etc.

### 3 — Joomla

Fuzzes Joomla paths including `administrator/`, `configuration.php`, `administrator/manifests/files/joomla.xml`, and component/module/plugin directories.

### 4 — Laravel

Looks for Laravel-specific files: `.env`, `telescope`, `horizon`, `storage/logs/`, `artisan`, `sanctum/csrf-cookie`, and API routes.

### 5 — Django

Targets Django admin (`admin/`, `admin/login/`), account endpoints, API paths, and static/media directories.

### 6 — ASP.NET / IIS

Covers ASP.NET and IIS artifacts: `web.config`, `global.asax`, `elmah.axd`, `trace.axd`, Swagger endpoints, and `.aspx` login pages.

### 7 — API / REST / GraphQL

Designed for API enumeration: version endpoints (`api/v1`, `v2`, `v3`), GraphQL (`graphql`, `graphiql`), Swagger/OpenAPI docs, OAuth token endpoints, and common REST paths.

### 8 — Generic

The kitchen-sink wordlist. Includes admin panels, config files, backups, log files, environment files, common CMS paths, version control artifacts (`.git/config`), and sensitive files. **Use this when you don't know what the target runs.**

### 9 — Custom

Only appears when you pass `-w /path/to/wordlist.txt`. Uses your wordlist exclusively.

---

## 💡 Examples

### Basic WordPress scan

```bash
mke-ffuf -u https://myblog.com
# → Select option 1 (WordPress)
```

### Scan an API with output file

```bash
mke-ffuf -u https://api.target.com -o api-results.txt
# → Select option 7 (API)
```

### Stealthy scan through Burp Suite

```bash
mke-ffuf -u https://target.com -x http://127.0.0.1:8080 -r 3 -t 5
# Low threads + rate limiting + proxy inspection
```

### Show only 200 and 403 responses

```bash
mke-ffuf -u https://target.com -mc 200,403
```

### Hide noisy 403s and redirects

```bash
mke-ffuf -u https://target.com -fc 301,302,403
```

### Scan a self-signed internal server

```bash
mke-ffuf -u https://192.168.1.100 -k
```

### Use a custom wordlist with high threads

```bash
mke-ffuf -u https://target.com -w /usr/share/seclists/Discovery/Web-Content/big.txt -t 50
# → Select option 9 (Custom)
```

### Full-featured scan

```bash
mke-ffuf -u https://target.com \
  -t 30 \
  -T 10 \
  -r 10 \
  -mc 200,301,403 \
  -x http://127.0.0.1:8080 \
  -o full-scan.txt \
  -k
```

---

## 🔍 How It Works

### The Scan Flow

```
┌──────────────────────────────────────────────────────────────┐
│  1. Parse arguments & validate inputs                        │
│  2. Show target type menu → load built-in wordlist           │
│  3. Merge SecLists (if installed) → deduplicate              │
│  4. Baseline: send 3 requests to random non-existent paths   │
│     → measure average response size of "404" pages           │
│  5. Fuzz: send concurrent requests for each wordlist entry   │
│     → filter by status code & soft-404 detection             │
│  6. Display color-coded results + save to file if -o used    │
└──────────────────────────────────────────────────────────────┘
```

### Smart 404 Detection (Anti-False-Positive)

Many websites return **HTTP 200** for pages that don't exist — showing a custom "Not Found" page instead of a proper 404. This floods results with junk.

mke-ffuf handles this by:

1. **Baselining**: Before scanning, it requests 3 random non-existent paths (e.g., `mke-a8f3kx9z`)
2. **Averaging**: Computes the average response size across those 3 samples
3. **Filtering**: During the scan, any HTTP 200 response whose size is within **5%** (minimum 20 bytes) of the baseline is flagged as a soft-404 and hidden

This eliminates most false positives without any manual tuning.

### Concurrency Model

```
Main process
  │
  ├── FIFO semaphore (named pipe with N tokens)
  │
  ├── Word 1 ──▶ acquire token ──▶ curl (background) ──▶ release token
  ├── Word 2 ──▶ acquire token ──▶ curl (background) ──▶ release token
  ├── Word 3 ──▶ waits...       ──▶ (slot opens)     ──▶ curl ──▶ release
  │   ...
  └── wait (all jobs)
```

Each thread slot is a byte in a FIFO pipe. Workers read a byte to "acquire" a slot and write a byte back to "release" it. This limits concurrency to exactly `-t` threads without external dependencies.

### User-Agent Rotation

Each request uses a randomly selected User-Agent from a pool of 5 realistic browser strings. This prevents trivial WAF rules that block repeated identical UAs.

---

## 📊 Understanding the Output

### Live Progress

During scanning, you'll see a live spinner with progress:

```
  ⠹  [142/387]
```

### Results

```
  ✓  200  https://target.com/admin          [1234b]
  *  301  https://target.com/login           [0b]    → https://target.com/login/
  *  403  https://target.com/.env            [287b]
  *  401  https://target.com/api/admin       [45b]
```

| Symbol | Meaning |
|---|---|
| `✓` (green) | HTTP 200 — the page exists and is accessible |
| `*` (light green) | Other notable status code (not 200) |

### Status Code Colors

| Color | Codes | Meaning |
|---|---|---|
| 🟢 Bright Green | `200` | OK — page exists |
| 🟢 Green | `201`, `204` | Created / No Content |
| 🔵 Blue | `301`, `302`, `307`, `308` | Redirect |
| 🟡 Yellow | `401`, `403` | Unauthorized / Forbidden (interesting!) |
| 🔴 Red | `5xx` | Server Error |
| ⚪ Dim | Everything else | Other |

### File Output (`-o`)

The output file contains clean, parseable lines:

```
[200] [1234b] https://target.com/admin
[301] [0b] https://target.com/login  -> https://target.com/login/
[403] [287b] https://target.com/.env
```

---

## ❓ FAQ

### Can I use this for bug bounty?

Yes — but always ensure the target is **in scope** and you have **authorization** to test. Many bug bounty programs explicitly allow directory/file discovery. Check the program's rules first.

### Why do I see no results?

Common reasons:

1. **The target returns custom 404 pages** that match the baseline — working as intended (false positive prevention)
2. **WAF is blocking you** — try `-r 3` to rate-limit, or `-x` to proxy through Burp and inspect responses
3. **Wrong target mode** — try Generic (option 8) for broader coverage
4. **Target is down** — check if the URL is reachable with `curl -I <url>`

### Can I combine `-mc` and `-fc`?

You can pass both, but **`-mc` takes priority**. When `-mc` is set, only those codes are shown — `-fc` is ignored. This matches how [ffuf](https://github.com/ffuf/ffuf) handles it.

### Does it work on macOS?

Yes, with one caveat: you need to install `flock`:

```bash
brew install flock
```

Everything else (`bash`, `curl`) ships with macOS.

### How do I update?

```bash
cd mke-ffuf
git pull
```

---

## ⚠️ Disclaimer

This tool is intended for **authorized security testing and educational purposes only**. Unauthorized access to computer systems is illegal. Always obtain proper authorization before scanning any target. The author assumes no liability for misuse of this tool.

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Open an issue for bugs or feature requests
- Submit a pull request with improvements
- Suggest new wordlists or target modes

---

<p align="center">
  Made with ☕ by <a href="https://github.com/RadhakrishnanSA">mke / RadhakrishnanSA</a>
</p>
```

