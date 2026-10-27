#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Pocket Agents: prepare agent directories and generate an s6 service for each
# ==============================================================================
set -e

AGENTS_ROOT=/config/agents

mkdir -p "${AGENTS_ROOT}"

# Services left over from a previous run (if the container was not recreated)
rm -rf /etc/services.d/agent-*

count=$(bashio::config 'agents|length')

# Check for duplicate names before creating anything
declare -A seen=()
for ((i = 0; i < count; i++)); do
    name=$(bashio::config "agents[${i}].name")
    if [[ -n "${seen[${name}]+x}" ]]; then
        bashio::exit.nok "Duplicate agent name: '${name}'. Agent names must be unique."
    fi
    seen[${name}]=1
done

for ((i = 0; i < count; i++)); do
    name=$(bashio::config "agents[${i}].name")
    title=$(bashio::config "agents[${i}].title" "${name}")
    spawn=$(bashio::config "agents[${i}].spawn" "same-dir")

    if bashio::config.false "agents[${i}].enabled"; then
        bashio::log.info "Agent '${name}' is disabled (enabled: false), skipping."
        continue
    fi

    dir="${AGENTS_ROOT}/${name}"
    mkdir -p "${dir}/.claude/skills"

    if [[ ! -f "${dir}/CLAUDE.md" ]]; then
        cat > "${dir}/CLAUDE.md" <<TEMPLATE
# ${title}

You are the "${name}" agent running in the Pocket Agents Home Assistant add-on.
You are controlled via Claude Code Remote Control from the Claude mobile app.

## Environment

- Working directory: ${dir}
- The Home Assistant configuration (/homeassistant) is not mapped; access HA via MCP or the API.
- Secrets from the add-on configuration are available as environment variables.
- MCP servers: .mcp.json in this directory.
- Skills: .claude/skills/ in this directory.

## Guidelines

- Keep answers short, I read them on my phone.
- Ask before making changes that cannot be undone.
TEMPLATE
        bashio::log.info "Agent '${name}': created CLAUDE.md from template."
    fi

    if [[ ! -f "${dir}/.mcp.json" ]]; then
        echo '{ "mcpServers": {} }' > "${dir}/.mcp.json"
    fi

    if [[ "${spawn}" == "worktree" ]] && ! git -C "${dir}" rev-parse --git-dir > /dev/null 2>&1; then
        bashio::log.warning "Agent '${name}': spawn=worktree requires a git repository in ${dir}."
    fi

    svc="/etc/services.d/agent-${name}"
    mkdir -p "${svc}"
    cat > "${svc}/run" <<RUN
#!/bin/sh
exec /usr/local/bin/agent-run ${i}
RUN
    chmod +x "${svc}/run"

    bashio::log.info "Agent '${name}' ready (${dir})."
done
