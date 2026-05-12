# Task 3: Secure Coding Review — Deliverable

**Primary language & platform:** Python 3 (SQLite, Flask web UI, CLI demos)  
**This repository:** [DAX1208/CodeAlpha_codereview](https://github.com/DAX1208/CodeAlpha_codereview)  
**Reference project:** Structure and teaching goals align with [CodeAlpha_Secure-Coding-Review-](https://github.com/Harsh-jethva/CodeAlpha_Secure-Coding-Review-) (vulnerable vs secure login).

**Codebase in this folder:**

| Artifact | Role |
|----------|------|
| `login_vulnerable.py` | Intentionally weak CLI login (SQLi, plain-text storage, MD5, secrets in code, verbose errors). |
| `login_secure.py` | Remediated CLI login (parameterized SQL, bcrypt, `.env`, logging). |
| `app.py` | Flask app exposing `/vulnerable` and `/secure` for side-by-side comparison. |
| `templates/` | Minimal HTML UI for the web lab. |

**Review goal:** Identify security weaknesses, document impact, and specify remediation aligned with OWASP-oriented secure coding practice.

---

## 1. Executive summary

This review combines **automated static analysis** (e.g. Bandit, `pip-audit`) and **manual inspection** of trust boundaries (HTTP form input in Flask, CLI stdin, SQLite queries, logging, and HTML output). Typical issues in this stack include SQL injection, weak password handling, secret leakage, and verbose error disclosure; the included **vulnerable** paths demonstrate several of these **on purpose** for study only.

The sections below document **methodology**, **representative findings** (including patterns illustrated by `login_vulnerable.py` and `app.py` → `login_vulnerable`), **remediation** (as implemented in `login_secure.py` and the `/secure` route), and **general best practices**. Attach tool logs from `bandit` / `pip-audit` when submitting coursework.

---

## 2. Methodology

### 2.1 Static analysis and dependency checks

| Layer | Tool / practice | What it finds |
|--------|-------------------|---------------|
| PHP | `composer audit` | Known CVEs in Composer packages |
| PHP | PHPStan / Psalm (stricter levels) | Type/logic issues; some risky patterns with plugins |
| PHP | Semgrep (PHP rules) | SQLi/XSS patterns, dangerous functions |
| JavaScript | `npm audit` / `yarn audit` / `pnpm audit` | Vulnerable npm packages |
| JavaScript | ESLint + `eslint-plugin-security` | `eval`, unsafe regex, object injection sinks |
| JavaScript | Semgrep (JS rules) | XSS sinks, unsafe DOM APIs |
| Python | `pip-audit` or Safety | Vulnerable PyPI packages |
| Python | Bandit | `exec`, `pickle`, `shell=True`, weak crypto |
| All | GitHub Dependabot / OSV | Cross-ecosystem advisory tracking |

### 2.2 Manual review focus

1. **Entry points:** All `$_GET`, `$_POST`, `$_REQUEST`, JSON bodies, headers, cookies, upload fields.  
2. **Data flow:** User input → validation → storage → output encoding.  
3. **Authentication:** Login, password reset, session fixation, `session_regenerate_id`, idle/logout, role checks on every protected action.  
4. **Authorization:** Server-side checks per resource ID (no “hidden field” security).  
5. **Secrets:** No keys in source; `.env` outside web root; correct permissions on XAMPP (`htdocs` vs config).  
6. **HTTP security:** HTTPS in production, `SameSite` cookies, CSRF tokens on POST/PUT/DELETE/state-changing requests.  
7. **Server config:** Directory listing off, default XAMPP/phpMyAdmin exposure disabled or strongly authenticated, `display_errors=Off` in production.

---

## 3. Findings summary

| ID | Title | Severity | Category |
|----|--------|-----------|-----------|
| F-01 | SQL injection via string-built queries | Critical | Injection |
| F-02 | Reflected/stored XSS via unescaped output | High | XSS |
| F-03 | Weak session handling (fixed session ID, broad cookie) | High | Broken authentication |
| F-04 | Missing CSRF protection on forms/actions | Medium | CSRF |
| F-05 | Insecure file upload (type/path not validated) | High | File handling |
| F-06 | Secrets or DB passwords in repository/config | Critical | Sensitive data exposure |
| F-07 | Python: `subprocess` with `shell=True` and user input | Critical | Injection |
| F-08 | Vulnerable npm/Composer dependencies | Variable | Using components with known vulnerabilities |

---

## 4. Detailed findings and remediation

### F-01 — SQL injection (Critical)

**Observation:** Building SQL with string concatenation or unparameterized interpolation from user input.

**Example (vulnerable pattern):**

```php
$id = $_GET['id'];
$sql = "SELECT * FROM users WHERE id = " . $id;
```

**Risk:** Attackers can read or modify database contents, bypass login, or destroy data.

**Remediation:** Use **prepared statements** with bound parameters only.

```php
$stmt = $pdo->prepare('SELECT * FROM users WHERE id = ?');
$stmt->execute([$_GET['id']]);
```

**Verification:** Retest with payloads such as `1 OR 1=1` and confirm they are treated as literal values, not SQL syntax.

---

### F-02 — Cross-site scripting (XSS) (High)

**Observation:** Echoing user-controlled data into HTML without encoding, or using unsafe JS APIs (`innerHTML`, `document.write`) with untrusted strings.

**PHP example (vulnerable):**

```php
echo "<div>Hello, " . $_GET['name'] . "</div>";
```

**Remediation:** Context-appropriate encoding (e.g. `htmlspecialchars($name, ENT_QUOTES, 'UTF-8')` for HTML body). Prefer templating systems that auto-escape by default.

**JavaScript:** Prefer `textContent`, avoid `innerHTML` for dynamic user content; if HTML is required, use a vetted sanitizer library and a strict allowlist.

---

### F-03 — Session security (High)

**Observation:** Session ID not rotated after login; cookies without `HttpOnly`/`Secure`/`SameSite`; sessions usable over HTTP.

**Remediation:**

- Call `session_regenerate_id(true)` after successful authentication.  
- Set cookie flags: `HttpOnly`, `Secure` (HTTPS), `SameSite=Lax` or `Strict` as appropriate.  
- Enforce HTTPS in production; never transmit session cookies on plain HTTP.

---

### F-04 — CSRF (Medium)

**Observation:** State-changing requests (password change, transfer, delete) accepted via POST without an unpredictable CSRF token tied to the session.

**Remediation:** Issue a per-session secret; include a hidden token in forms and validate server-side on POST/PUT/PATCH/DELETE. For APIs, use anti-CSRF tokens or SameSite cookies plus careful CORS and custom headers where applicable.

---

### F-05 — Insecure file upload (High)

**Observation:** Saving uploads under web root with original extension; MIME/extension trust only client-side; no content inspection.

**Remediation:**

- Store uploads **outside** the web root or deny script execution in upload directories (Apache `<Directory>` / `php_flag engine off`).  
- Generate random filenames; allowlist extensions; verify content type with `finfo`; size limits; virus scan if policy requires.

---

### F-06 — Secrets in source or web-accessible config (Critical)

**Observation:** Database passwords, API keys, or `.env` committed to Git or placed under `htdocs` and fetchable.

**Remediation:**

- Use environment variables or config **outside** the document root.  
- Add `.env` to `.gitignore`; rotate any leaked keys.  
- Restrict file permissions; never return config files as static assets.

---

### F-07 — Python command injection (Critical)

**Observation:** Building shell commands from user input or using `subprocess` with `shell=True`.

**Remediation:** Use argument lists: `subprocess.run(['tool', '--input', path], ...)` with validated paths; avoid `shell=True`. Never unpickle untrusted data.

---

### F-08 — Vulnerable dependencies

**Observation:** Outdated `composer.lock` / `package-lock.json` / `requirements.txt` with known CVEs.

**Remediation:** Run ecosystem audits regularly; pin versions; upgrade patched releases; review breaking changes in release notes.

---

## 5. Secure coding best practices (PHP, XAMPP, JS, Python)

**PHP**

- Default deny: validate all input with allowlists where possible; enforce types and ranges.  
- Always use PDO/MySQLi prepared statements; disable `mysqli_multi_query` abuse patterns in app code.  
- Never trust `mail()` headers built from user input (header injection).  
- Turn off `display_errors` in production; log errors securely server-side.

**XAMPP / Apache**

- Do not expose phpMyAdmin to the internet without strong auth and network restriction.  
- Use separate vhosts and document roots per app; least-privilege DB users (no `FILE` privilege unless needed).

**JavaScript**

- Treat all server responses as untrusted until validated; enforce authorization on the **server**.  
- Avoid storing sensitive tokens in `localStorage` if XSS is possible; prefer `HttpOnly` cookies for session tokens where architecture allows.

**Python**

- Use parameterized DB APIs; avoid string formatting for SQL.  
- Use secrets management for keys; lock down debug (`DEBUG=False`) and framework secret keys in production.

---

## 6. Documentation checklist for your submission

- [ ] State clearly: **language(s)**, **application name/description**, and **review scope** (directories or modules).  
- [ ] List **tools run** (commands and versions if possible) and attach or summarize output.  
- [ ] For each finding: **severity**, **location**, **description**, **exploit scenario (short)**, **remediation**, **retest notes**.  
- [ ] Add a short **conclusion** and **prioritized fix order** (Critical → High → Medium → Low).

---

## 7. References (orientation)

- OWASP Top 10: https://owasp.org/www-project-top-ten/  
- OWASP PHP Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/PHP_Configuration_Cheat_Sheet.html  
- OWASP XSS Prevention: https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html  

---

*This document was prepared as a template and exemplar aligned with Task 3 requirements: language/application scope, vulnerability identification, tool-assisted and manual methodology, recommendations, and remediation. Substitute project-specific paths, screenshots, and tool logs when auditing your own codebase.*
