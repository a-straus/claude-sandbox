#!/usr/bin/env bash
set -euo pipefail

bash -n bin/_lib.sh bin/spawn bin/integrate bin/list-agents bin/orchestrate \
    bin/attempt bin/advise bin/agent bin/usage bin/abandon
bash tests/orchestrator-smoke.sh
