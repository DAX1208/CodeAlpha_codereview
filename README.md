# CodeAlpha — Secure Coding Review (Python)

**Repository:** [github.com/DAX1208/CodeAlpha_codereview](https://github.com/DAX1208/CodeAlpha_codereview)

Educational project: **vulnerable** vs **secure** login implementations for secure coding review and remediation practice. Structure inspired by [CodeAlpha_Secure-Coding-Review-](https://github.com/Harsh-jethva/CodeAlpha_Secure-Coding-Review-).

## Contents

| File | Purpose |
|------|---------|
| `login_vulnerable.py` | CLI demo — intentional weaknesses (SQL injection, plain-text passwords, MD5, hardcoded secrets, verbose errors). |
| `login_secure.py` | CLI demo — fixes (parameterized queries, bcrypt, `.env`, logging). |
| `app.py` | Flask web app: `/vulnerable` and `/secure` routes with shared templates. |
| `templates/` | HTML for the web lab (missing from upstream; added here so `app.py` runs). |
| `requirements.txt` | Dependencies including `bandit` for static analysis. |
| `.env.example` | Copy to `.env`; never commit `.env`. |
| `SECURE_CODING_REVIEW_REPORT.md` | Written findings, methodology, and remediation template. |
| `run.bat` | Windows: create venv, install deps, copy `.env`, start Flask. |

## Clone

```bash
git clone https://github.com/DAX1208/CodeAlpha_codereview.git
cd CodeAlpha_codereview
```

## Easiest way (Windows)

Double-click **`run.bat`** in this folder (or run it from Command Prompt).  
First run creates `.venv`, installs packages, copies `.env.example` → `.env`, then starts the server. Open **http://127.0.0.1:5000**

## Setup (manual)

```bash
cd c:\xampp\htdocs\codealpha_codereview
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

Edit `.env` and set a long random `SECRET_KEY`.

## Run — CLI

```bash
python login_vulnerable.py
python login_secure.py
```

Sample credentials after setup: username `admin`, password `password123` (secure path verifies against bcrypt hash).

## Run — Web (Flask)

```bash
python app.py
```

Open `http://127.0.0.1:5000/` — choose **Vulnerable** or **Secure**.

## Static analysis (assignment-friendly)

```bash
bandit -r . -x ./.venv -f txt
pip-audit
```

## Security notes

- **Vulnerable** scripts and `/vulnerable` are for **local learning only**; do not deploy publicly.
- SQLite `.db` files and `.env` are listed in `.gitignore`.
- Keep `debug=False` if you ever expose the Flask app beyond localhost.

## Reference

Upstream inspiration: [github.com/Harsh-jethva/CodeAlpha_Secure-Coding-Review-](https://github.com/Harsh-jethva/CodeAlpha_Secure-Coding-Review-)
video link: https://drive.google.com/file/d/1A1zO8xjYzfM2GKOJw8CIq_DldaQ6w7EM/view?usp=sharing
