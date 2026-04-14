# Security Policy
<!-- BPMN Phase 1.5 – Security Baseline -->

## Supported Versions

| Version | Supported |
|---------|-----------|
| 2.2.x   | ✅ Active |
| < 2.2   | ❌ No longer supported |

## Reporting a Vulnerability

**Please do not open a public issue for security vulnerabilities.**

If you discover a security vulnerability in Virtual Hosts, please report it
responsibly:

1. **GitHub Private Vulnerability Reporting** (preferred):  
   Use the [Security tab → Report a vulnerability](../../security/advisories/new)
   feature in this repository.

2. **Email**:  
   Contact the repository owner directly via the email listed on their
   [GitHub profile](https://github.com/camillanapoles).

### What to include

- Description of the vulnerability and its impact
- Steps to reproduce (proof-of-concept if possible)
- Affected versions
- Suggested fix (optional)

### Response timeline

| Milestone | Target |
|-----------|--------|
| Acknowledgement | 72 hours |
| Initial assessment | 7 days |
| Patch / advisory | 30 days |

## Known Security Considerations

### VPN Permission

Virtual Hosts uses Android's VPN API (`VpnService`) to intercept DNS
queries without requiring root access. The VPN tunnel only modifies DNS
resolution — it does **not** decrypt or proxy general network traffic.
The VPN profile is local-only and never routes data to an external server.

### google-services.json

The `google-services.json` file in this repository contains Firebase
configuration IDs (project number, OAuth client ID, API key) for the
Firebase Analytics integration. These values are designed to be public for
client-side Android apps; they do **not** grant administrative access to
the Firebase project. However, users are encouraged to review their Firebase
security rules and API key restrictions via the Google Cloud Console.

### Exposed Analytics ID

The Baidu Analytics tracker ID (`a7bceb64e8`) is embedded in the Android
Manifest. This is a public analytics identifier and does not constitute a
credential. Still, users who prefer zero telemetry may disable analytics
in the app settings.

## Security Best Practices for Contributors

- **Never commit** keystore files (`.jks`, `.keystore`, `.key`).
- **Never commit** signing passwords, API secrets, or personal tokens.
- All CI/CD pipeline actions must be **SHA-pinned** (see `.github/workflows/`).
- Dependency updates should go through Dependabot PR reviews and the
  automated security scan before merging.
