```text
███╗   ███╗██╗  ██╗███████╗      ███████╗███████╗██╗   ██╗███████╗
████╗ ████║██║ ██╔╝██╔════╝      ██╔════╝██╔════╝██║   ██║██╔════╝
██╔████╔██║█████╔╝ █████╗        █████╗  █████╗  ██║   ██║█████╗  
██║╚██╔╝██║██╔═██╗ ██╔══╝        ██╔══╝  ██╔══╝  ██║   ██║██╔══╝  
██║ ╚═╝ ██║██║  ██╗███████╗      ██║     ██║     ╚██████╔╝██║
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝      ╚═╝     ╚═╝      ╚═════╝ ╚═╝

                         mke-ffuf
                 make it easier than FFUF


'''

mke-ffuf

mke-ffuf is a guided and intelligent wrapper around FFUF designed to make web fuzzing easier, cleaner, and more interactive.

While using FFUF, the output can become very large, making it hard to scroll, manually filter responses, and identify unique or meaningful results. Repeating filters based on size, words, and lines can be time-consuming during recon.

mke-ffuf solves this by running FFUF silently in the background, automatically filtering generic responses, highlighting unique endpoints, and guiding the user through different fuzzing workflows.

This tool does not replace FFUF — it improves usability.

✨ Features

Wizard-style interactive workflow

Uses FFUF as the fuzzing engine

Automatic filtering of generic responses

Displays only unique and interesting results

Basic vulnerability-style tagging (ADMIN, LOGIN, AUTH_REQUIRED, etc.)

SecLists auto-detection and optional auto-install

Clean terminal-friendly output

Designed for Linux environments

🛠 Requirements

Linux

Python 3.8+

FFUF installed and available in $PATH

Git (required only if SecLists needs to be installed automatically)

📦 Installation
1️⃣ Install FFUF
sudo apt install ffuf


Verify installation:

ffuf -h

2️⃣ Clone mke-ffuf
git clone https://github.com/RadhakrishnanSA/mke-ffuf.git
cd mke-ffuf

3️⃣ Make the script executable
chmod +x mke-ffuf.py

▶️ Usage

Run the tool:

./mke-ffuf.py

Workflow

Tool launches with banner

Checks for SecLists

Installs or locates SecLists if required

Prompts for target URL

Allows selection of fuzzing type

Shows example FFUF URL

Runs FFUF silently

Displays only unique and tagged results

Asks whether to continue with another scan

🔍 Supported Scan Types

Directory fuzzing

File fuzzing

Parameter fuzzing

Password fuzzing

⚠️ Disclaimer

This tool is intended for educational purposes and authorized security testing only.

Do NOT use this tool against systems you do not own or have explicit permission to test.

📄 License

MIT License

🧠 Notes

SecLists is not included in this repository

mke-ffuf can automatically install SecLists when needed

Designed to reduce FFUF output noise and improve recon efficiency

