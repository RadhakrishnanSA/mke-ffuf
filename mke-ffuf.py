#!/usr/bin/env python3

import subprocess
import json
import os
import sys
from collections import Counter

RAW_JSON = "mke_raw.json"

# ---------- UI ----------
def banner():
    print("\033[92m")
    print(r"""
███╗   ███╗██╗  ██╗███████╗      ███████╗███████╗██╗   ██╗███████╗
████╗ ████║██║ ██╔╝██╔════╝      ██╔════╝██╔════╝██║   ██║██╔════╝
██╔████╔██║█████╔╝ █████╗        █████╗  █████╗  ██║   ██║█████╗  
██║╚██╔╝██║██╔═██╗ ██╔══╝        ██╔══╝  ██╔══╝  ██║   ██║██╔══╝  
██║ ╚═╝ ██║██║  ██╗███████╗      ██║     ██║     ╚██████╔╝██║
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝      ╚═╝     ╚═╝      ╚═════╝ ╚═╝

                    MKE-FFUF
            make it easier than FFUF
""")
    print("\033[0m")

# ---------- FFUF RUNNERS ----------
def run_ffuf(cmd):
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except KeyboardInterrupt:
        print("\n[!] Scan interrupted")
        sys.exit(0)

def run_get(url, wordlist):
    run_ffuf([
        "ffuf", "-s",
        "-u", url,
        "-w", wordlist,
        "-o", RAW_JSON, "-of", "json"
    ])

def run_post(url, data, wordlist):
    run_ffuf([
        "ffuf", "-s",
        "-X", "POST",
        "-u", url,
        "-d", data,
        "-H", "Content-Type: application/x-www-form-urlencoded",
        "-w", wordlist,
        "-o", RAW_JSON, "-of", "json"
    ])

# ---------- ANALYZER ----------
def analyze():
    if not os.path.exists(RAW_JSON):
        return []

    with open(RAW_JSON) as f:
        data = json.load(f)

    results = data.get("results", [])
    if not results:
        return []

    fps = [(r["length"], r["words"], r["lines"]) for r in results]
    common_fp = Counter(fps).most_common(1)[0][0]

    unique = []
    for r in results:
        if (r["length"], r["words"], r["lines"]) != common_fp:
            unique.append(r)

    return unique

def show(results):
    for r in results:
        print(f"[+] {r['input']} | {r['status']} | size={r['length']}")

# ---------- MAIN ----------
def main():
    banner()

    base = input("Enter target base URL: ").strip()

    while True:
        print("""
1) Directory fuzzing
2) File fuzzing
3) Parameter discovery (GET + POST)
4) Login fuzzing (username / password)
""")
        choice = input("Choice: ").strip()

        # ---------- DIRECTORY ----------
        if choice == "1":
            url = base.rstrip("/") + "/FUZZ"
            run_get(url, "wordlists/dirs.txt")

        # ---------- FILE ----------
        elif choice == "2":
            url = base.rstrip("/") + "/FUZZ.php"
            run_get(url, "wordlists/files.txt")

        # ---------- PARAM DISCOVERY ----------
        elif choice == "3":
            method = input("GET or POST? [G/P]: ").lower()

            if method == "g":
                url = base + "?FUZZ=test"
                run_get(url, "wordlists/params.txt")
            else:
                run_post(base, "FUZZ=test", "wordlists/params.txt")

        # ---------- LOGIN FUZZ ----------
        elif choice == "4":
            uname = input("Username parameter name: ").strip()
            pwd = input("Password parameter name: ").strip()
            mode = input("Fuzz (u)p / (p)ass / (b)oth?: ").lower()

            if mode == "u":
                data = f"{uname}=FUZZ&{pwd}=test"
                run_post(base, data, "wordlists/usernames.txt")

            elif mode == "p":
                data = f"{uname}=test&{pwd}=FUZZ"
                run_post(base, data, "wordlists/passwords.txt")

            else:
                data = f"{uname}=FUZZ&{pwd}=FUZZ"
                run_post(base, data, "wordlists/passwords.txt")

        else:
            print("Invalid choice")
            continue

        results = analyze()
        if results:
            show(results)
        else:
            print("[-] No unique responses detected.")

        if input("Another scan? [Y/n]: ").lower() == "n":
            break

        if os.path.exists(RAW_JSON):
            os.remove(RAW_JSON)

if __name__ == "__main__":
    main()
