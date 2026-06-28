#!/usr/bin/env bash
# shellcheck shell=bash

ndm_require_lib version

ndm_get_installed_version

for cmd in check download install health diagnose report; do
    cat > "src/commands/${cmd}.sh" <<'EOF'
#!/usr/bin/env bash
# shellcheck shell=bash

ndm_fatal "Command not implemented yet."
EOF
done
