
███╗   ███╗██╗  ██╗███████╗      ███████╗███████╗██╗   ██╗███████╗
████╗ ████║██║ ██╔╝██╔════╝      ██╔════╝██╔════╝██║   ██║██╔════╝
██╔████╔██║█████╔╝ █████╗        █████╗  █████╗  ██║   ██║█████╗  
██║╚██╔╝██║██╔═██╗ ██╔══╝        ██╔══╝  ██╔══╝  ██║   ██║██╔══╝  
██║ ╚═╝ ██║██║  ██╗███████╗      ██║     ██║     ╚██████╔╝███████╗
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝      ╚═╝     ╚═╝      ╚═════╝ ╚══════╝

                         mke-ffuf
                 make it easier than ffuf


---

# mke-ffuf

**mke-ffuf** is a revised version of **ffuf** focused on ease of use and cleaner results.

While using ffuf, the output can become very large, making it hard to scroll through results, manually apply filters, and identify unique or meaningful responses. Repeated filtering by size, words, and lines often slows down recon.

To solve this, **mke-ffuf** automatically analyzes ffuf results, filters out generic responses, and displays only unique outputs—making web fuzzing simpler and more comfortable.

This tool does not replace ffuf.
It makes ffuf easier to use.

---

## ✨ Features

* Silent ffuf execution (no progress spam)
* Automatic filtering of generic responses
* Detects repeated response templates (size, words, lines)
* Displays only unique and meaningful results
* Interactive flow to try different fuzzing types
* Clean terminal-friendly output
* Designed for Linux environments

---

## 🧠 Why mke-ffuf?

When running ffuf:

* Output grows very large
* Scrolling becomes difficult
* Manual filtering takes time
* Unique responses are easy to miss

**mke-ffuf** handles this automatically so you can focus on what matters.

---

## 🛠 Requirements

* Linux
* Python 3.8+
* ffuf installed and available in `$PATH`

---

## 📦 Installation

```bash
git clone https://github.com/yourusername/mke-ffuf.git
cd mke-ffuf
chmod +x mke-ffuf.py
```

---

## ▶️ Usage

```bash
./mke-ffuf.py
```

The tool will:

1. Ask for the target URL
2. Run ffuf silently in the background
3. Filter generic responses
4. Show only unique results
5. Suggest other fuzzing methods if needed

---

## ⚠️ Disclaimer

Use only on targets you own or have permission to test.

---

## 📄 License

MIT License


