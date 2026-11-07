---
name: bug-hunt
description: Drive an authorized web, API, or network bug-hunting engagement end to end — scope checks, recon, surface mapping, vulnerability-class testing, evidence capture, and report writing. Use when the user mentions bug bounty, pentest, recon, fuzzing, vulnerability hunting, security audit, or asks to test a target for security issues.
---

# Bug Hunt

Authorized security testing only. Confirm scope and written authorization before any active testing.

## 1. Gate every engagement

Ask or confirm, and stop if any answer is missing:

- Written authorization and the exact in-scope assets (domains, IPs, apps, accounts).
- Exclusions: out-of-scope hosts, destructive tests, rate limits, prohibited techniques.
- Testing window, contact, and disclosure rules.
- Whether the target is production; confirm DoS, brute-force, and data-access limits.

Never test third-party infrastructure (shared hosting, CDNs, SaaS) unless explicitly in scope. Prefer non-destructive proof over exploitation.

## 2. Set up the workspace

Run the herdr launcher (`prefix+alt+p`) or `herdr-pentest <path>` to get recon, web, AI, and notes tabs. Save pane output for evidence with `prefix+alt+s`. Keep the report in `~/Study/BugHunt`.

Installed tooling on this host: `nmap`, `feroxbuster`, `msfconsole`, `wireshark`, `tshark`, `hashcat`, `burp` MCP (when Burp is running on 127.0.0.1:9876), `arson-framework` MCP (127.0.0.1:3001).

## 3. Recon

1. Passive: DNS, certificates, search engines, ASN, public repos, job posts, Wayback.
2. Active: `nmap -sV -sC -Pn <target>`, then `nmap -p- --min-rate 1000 <target>` only within rate limits.
3. Content: `feroxbuster -u https://<target> -w <wordlist> -d 2 -t 20`.
4. Record every host, port, service version, and interesting path in the notes tab.

## 4. Surface map

Group by reachable asset and attack surface: auth, APIs, uploads, SSRF-capable fetchers, GraphQL, websockets, admin panels, file handling, third-party integrations. Prioritize by exposure x impact.

## 5. Test by class

Work one hypothesis at a time and keep raw requests and responses.

- Auth/session: default creds, MFA bypass, token lifetime, IDOR, privilege boundaries.
- Injection: SQLi, NoSQL, SSTI, command, LDAP; confirm with time-based or boolean proof, not data exfiltration.
- Web: XSS stored/reflected/DOM, CSRF, SSRF, open redirect, CORS, host-header issues.
- Access control: horizontal/vertical IDOR, forced browsing, method tampering.
- Files: upload bypass, path traversal, LFI/RFI, archive extraction.
- APIs: schema diffing, mass assignment, rate limits, JWT claims/kid/jku, GraphQL introspection.
- Infrastructure: TLS/cert issues, exposed management services, default panels, outdated components with a safe version check.

Use Burp or `curl` for manual requests; use `nmap` NSE and `msfconsole` only for non-destructive validation.

## 6. Evidence

For each finding save: affected endpoint, exact request, response marker, timestamp, screenshot or pane snapshot, and reproduction steps. Do not include live secrets in notes; redact values.

## 7. Report

Write to `~/Study/BugHunt/notes/`. Use: title, severity (CVSS vector), affected asset, preconditions, reproduction steps, evidence, impact, remediation, references. Rank by exploitability x impact; include a short executive summary and a failed-tests appendix so coverage is visible.

## Guardrails

- No persistence, lateral movement, or data destruction beyond what authorization permits.
- Stop and report immediately on evidence of real user data or a critical production exposure.
- Prefer the smallest payload that proves impact; clean up test artifacts.
