# mke-ffuf

A focused web fuzzer. Copy the script, run it, get results.

No installation. No dependencies. No package managers. Just `curl` and `bash`.

---

## Why

Most fuzzers need Go, Python, or a full install. This is a single `.sh` file — copy it to any Linux machine and run it. Works on Kali, Parrot, Ubuntu, Arch, WSL out of the box.

---

## Setup

```bash
wget https://raw.githubusercontent.com/RadhakrishnanSA/mke-ffuf/main/mke-ffuf.sh
chmod +x mke-ffuf.sh
./mke-ffuf.sh -u https://target.com
```

Or just paste the script content into a file, `chmod +x` it, and run.

---

## How it works

On launch it asks what type of target you're fuzzing, then loads the matching wordlist automatically.

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
  9  Custom wordlist (your own file)
```

Pick a number → it fuzzes → results print live.

---

## Output

```
  ✓  200  https://target.com/wp-login.php  [1842b]
  *  301  https://target.com/wp-admin      [0b]  → https://target.com/wp-admin/
  *  403  https://target.com/wp-content/   [278b]
```

- `✓` = 200 OK
- `*` = anything else worth looking at (301, 302, 401, 403, 500)
- 404s and noise are silently dropped

---

## Usage

```bash
./mke-ffuf.sh -u <URL> [options]
```

| Flag | Description | Default |
|------|-------------|---------|
| `-u` | Target URL (required) | — |
| `-t` | Threads | 20 |
| `-T` | Timeout (seconds) | 8 |
| `-r` | Rate limit (req/sec) | unlimited |
| `-w` | Custom wordlist file | — |
| `-o` | Save output to file (plain text) | — |
| `-oj` | Save output as JSON (use with `-o`) | — |
| `-x` | Proxy (e.g. Burp) | — |
| `-mc` | Only show these status codes | — |
| `-fc` | Hide these status codes | — |
| `-k` | Skip TLS certificate check | — |

---

## Examples

```bash
# Basic scan
./mke-ffuf.sh -u https://target.com

# Save results to file
./mke-ffuf.sh -u https://target.com -o results.txt

# Through Burp
./mke-ffuf.sh -u https://target.com -x http://127.0.0.1:8080

# Only show 200s and 301s
./mke-ffuf.sh -u https://target.com -mc 200,301

# Hide 403s
./mke-ffuf.sh -u https://target.com -fc 403

# Use your own wordlist
./mke-ffuf.sh -u https://target.com -w /usr/share/seclists/Discovery/Web-Content/common.txt

# JSON output (pipe to jq)
./mke-ffuf.sh -u https://target.com -oj -o results.json
cat results.json | jq '.[] | select(.status == 200)'

# Slow scan to avoid WAF bans
./mke-ffuf.sh -u https://target.com -r 5 -t 5

# Self-signed cert target
./mke-ffuf.sh -u https://target.com -k
```

---

## Requirements

- `bash`
- `curl`
- `flock` (part of `util-linux`, already on most distros)

If seclists is installed (`/usr/share/seclists`), it auto-merges the relevant wordlist on top of the built-in one.

---

## Author

mke / [RadhakrishnanSA](https://github.com/RadhakrishnanSA)
