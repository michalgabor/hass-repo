#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Pocket Agents: pripraví adresáre agentov a vygeneruje pre každého s6 službu
# ==============================================================================
set -e

AGENTS_ROOT=/config/agents

mkdir -p "${AGENTS_ROOT}"

# Služby z predchádzajúceho behu (ak kontajner nebol znovu vytvorený)
rm -rf /etc/services.d/agent-*

count=$(bashio::config 'agents|length')

# Duplicitné mená kontrolujeme skôr, než čokoľvek vytvoríme
declare -A seen=()
for ((i = 0; i < count; i++)); do
    name=$(bashio::config "agents[${i}].name")
    if [[ -n "${seen[${name}]+x}" ]]; then
        bashio::exit.nok "Duplicitné meno agenta: '${name}'. Mená agentov musia byť unikátne."
    fi
    seen[${name}]=1
done

for ((i = 0; i < count; i++)); do
    name=$(bashio::config "agents[${i}].name")
    title=$(bashio::config "agents[${i}].title" "${name}")
    spawn=$(bashio::config "agents[${i}].spawn" "same-dir")

    if bashio::config.false "agents[${i}].enabled"; then
        bashio::log.info "Agent '${name}' je vypnutý (enabled: false), preskakujem."
        continue
    fi

    dir="${AGENTS_ROOT}/${name}"
    mkdir -p "${dir}/.claude/skills"

    if [[ ! -f "${dir}/CLAUDE.md" ]]; then
        cat > "${dir}/CLAUDE.md" <<TEMPLATE
# ${title}

Si agent "${name}" bežiaci v Home Assistant doplnku Pocket Agents.
Ovládaný si cez Claude Code Remote Control z Claude appky v telefóne.

## Prostredie

- Pracovný adresár: ${dir}
- Konfigurácia Home Assistant: /homeassistant nie je namapovaná; na HA pristupuj cez MCP alebo API.
- Tajomstvá z konfigurácie doplnku sú dostupné ako premenné prostredia.
- MCP servery: .mcp.json v tomto adresári.
- Skills: .claude/skills/ v tomto adresári.

## Pokyny

- Odpovedaj stručne, správy čítam na mobile.
- Pred zmenami, ktoré nejdú vrátiť, sa opýtaj.
TEMPLATE
        bashio::log.info "Agent '${name}': vytvorený CLAUDE.md zo šablóny."
    fi

    if [[ ! -f "${dir}/.mcp.json" ]]; then
        echo '{ "mcpServers": {} }' > "${dir}/.mcp.json"
    fi

    if [[ "${spawn}" == "worktree" ]] && ! git -C "${dir}" rev-parse --git-dir > /dev/null 2>&1; then
        bashio::log.warning "Agent '${name}': spawn=worktree vyžaduje git repozitár v ${dir}."
    fi

    svc="/etc/services.d/agent-${name}"
    mkdir -p "${svc}"
    cat > "${svc}/run" <<RUN
#!/bin/sh
exec /usr/local/bin/agent-run ${i}
RUN
    chmod +x "${svc}/run"

    bashio::log.info "Agent '${name}' pripravený (${dir})."
done
