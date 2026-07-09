# Network

Loaded on demand when a worker hits a network failure. **Read this before treating
a network problem as an escalation.**

GitHub, npm, and the Anthropic API are allowlisted; everything else is blocked. If a
worker needs another host (PyPI, a CDN, etc.), that is an escalation — the human
must add it to `.devcontainer/init-firewall.sh` and rebuild. Repeated network
failures to an allowlisted host usually mean rotated CDN IPs; the outer loop
refreshes the firewall periodically on its own.
