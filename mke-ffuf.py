#!/usr/bin/env python3

import os
import sys
import json
import subprocess
from collections import Counter

SECLISTS_DEFAULT = os.path.expanduser("~/SecLists")
TMP_JSON = "ffuf_raw.json"

# -------------------- UI --------------------

def banner():
    print("\033[92m")
    print(r"""
███╗   ███╗██╗  ██╗███████╗      ███████╗███████╗██╗   ██╗███████╗
████╗ ████║██║ ██╔╝██╔════╝      ██╔════╝██╔════╝██║   ██║██╔════╝
██╔████╔██║█████╔╝ █████╗        █████╗  █████╗  ██║   ██║█████╗  
██║╚██╔╝██║██╔═██╗ ██╔══╝        ██╔══╝  ██╔══╝  ██║   ██║██╔══╝  
██║ ╚═╝ ██║██║  ██╗███████╗      ██║     ██║     ╚██████╔╝██║     
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝      ╚═╝     ╚═╝      ╚═════╝ ╚═╝     

                        mke-ffuf
                make it easier than FFUF
""")
    print("\033[0m")

# -------------------- SecLists Setup --------------------

def install_seclists():
    subprocess.run([
        "git", "clone",
        "https://github.com/danielmiessler/SecLists.git",
        SECLISTS_DEFAULT
    ])

def setup_seclists():
    print("[*] Checking SecLists setup...\n")

    have = input("Do you already have SecLists? [Y/n]: ").strip().lower()
    if have == "n":
        install = input("Do you want me to install SecLists for you? [Y/n]: ").strip().lower()
        if install == "n":
            sys.exit("[-] SecLists is required. Exiting.")
        install_seclists()
        return SECLISTS_DEFAULT

    default = input("Is SecLists located at ~/SecLists ? [Y/n]: ").strip().lower()
    if default == "y":
        return SECLISTS_DEFAULT

    custom = input("Enter the full SecLists path: ").strip()
    if not os.path.isdir(custom):
        sys.exit("[-] Invalid SecLists path.")
    return custom

# -------------------- Scan Selection --------------------

def choose_scan_type():
    print("""
Select scan type:
1) Directory fuzzing
2) File fuzzing
3) Parameter fuzzing
4) Password fuzzing
""")
    return input("Choice: ").strip()

def show_example(choice):
    examples = {
        "1": "https://example.com/FUZZ",
        "2": "https://example.com/FUZZ.php",
        "3": "https://example.com/?FUZZ=test",
        "4": "https://example.com/login"
    }
    print(f"Example URL: {examples[choice]}")

# -------------------- FFUF Logic --------------------

def run_ffuf(url, wordlist):
    subprocess.run([
        "ffuf", "-s",
        "-u", url,
        "-w", wordlist,
        "-o", TMP_JSON,
        "-of", "json"
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def infer_tag(result):
    fuzz = result["input"].get("FUZZ", "").lower()
    status = result["status"]

    if status in (401, 403):
        return "AUTH_REQUIRED"
    if "admin" in fuzz:
        return "ADMIN"
    if "login" in fuzz:
        return "LOGIN"
    if "upload" in fuzz:
        return "UPLOAD"
    if "api" in fuzz:
        return "API"
    if status in (301, 302):
        return "REDIRECT"
    if status == 200:
        return "INTERESTING"

    return "UNKNOWN"

def analyze_results():
    with open(TMP_JSON) as f:
        data = json.load(f)

    results = data.get("results", [])
    if not results:
        return []

    fps = [(r["length"], r["words"], r["lines"]) for r in results]
    common_fp = Counter(fps).most_common(1)[0][0]

    unique = []
    for r in results:
        if (r["length"], r["words"], r["lines"]) != common_fp:
            r["tag"] = infer_tag(r)
            unique.append(r)

    return unique

def print_results(results):
    print("\n[+] Unique results found:\n")
    for r in results:
        print(f"{r['input'].get('FUZZ',''):15} "
              f"| {r['status']} "
              f"| {r['tag']:15} "
              f"| size={r['length']}")

# -------------------- Main Wizard Flow --------------------

def main():
    banner()

    print("[*] Launching mke-ffuf wizard...\n")

    seclists = setup_seclists()

    print("\n[+] SecLists ready.")
    target = input("\nEnter target base URL (for reference): ").strip()

    wordlists = {
        "1": f"{seclists}/Discovery/Web-Content/common.txt",
        "2": f"{seclists}/Discovery/Web-Content/raft-small-files.txt",
        "3": f"{seclists}/Discovery/Web-Content/burp-parameter-names.txt",
        "4": f"{seclists}/Passwords/Common-Credentials/10-million-password-list-top-100.txt"
    }

    while True:
        choice = choose_scan_type()
        show_example(choice)

        ffuf_url = input("Paste the FFUF URL to test: ").strip()

        print("\n[*] Running FFUF...\n")
        run_ffuf(ffuf_url, wordlists[choice])

        results = analyze_results()
        if results:
            print_results(results)
        else:
            print("[-] No unique responses detected.")

        again = input("\nDo you want to perform another scan? [Y/n]: ").strip().lower()
        if again == "n":
            break

        if os.path.exists(TMP_JSON):
            os.remove(TMP_JSON)

    print("\n[+] Recon finished. Exiting.")

if __name__ == "__main__":
    main()
