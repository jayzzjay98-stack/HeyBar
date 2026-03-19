# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.2.x   | ✓         |
| 0.1.x   | ✗         |

## Reporting a Vulnerability

If you discover a security vulnerability in HeyBar, please report it **privately** rather than opening a public issue.

**How to report:**

1. Open a [GitHub Security Advisory](https://github.com/jayzzjay98-stack/HeyBar/security/advisories/new) — this keeps the report confidential until a fix is released.
2. Include a clear description of the vulnerability, steps to reproduce, and the potential impact.

You can expect an acknowledgement within **72 hours** and a resolution or update within **14 days** for critical issues.

## Security Considerations

HeyBar requests two macOS permissions that involve elevated system access:

**Accessibility (required for CleanKey)**
CleanKey uses `CGEventTap` at the session level to intercept keyboard and mouse events. This is the same API used by screen readers and productivity tools. The tap is active only while CleanKey mode is running and is torn down immediately on unlock.

**Automation (required for Hide Dock and Hide Bar)**
Hide Dock and Hide Bar send scripted AppleEvents to `System Events` to toggle macOS auto-hide settings. No other application data is read or modified.

HeyBar does not make network requests, collect analytics, or transmit any data off-device, with the exception of the optional update check, which sends a single authenticated read request to the GitHub Releases API.
