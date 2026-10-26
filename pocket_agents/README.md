# Pocket Agents

Home Assistant doplnok, ktorý spúšťa viac **Claude Code Remote Control** serverov
("agentov"). Každý agent beží vo vlastnom adresári `/addon_configs/<repo>_pocket_agents/agents/<name>/`
(v kontajneri `/config/agents/<name>/`) s vlastným `CLAUDE.md`, `.mcp.json`
a `.claude/skills/`. Agentov ovládaš z Claude appky v telefóne alebo z
[claude.ai/code](https://claude.ai/code).

> Remote Control vyžaduje predplatné Claude Pro, Max, Team alebo Enterprise
> a prihlásenie cez claude.ai. API kľúč nefunguje.

## Inštalácia

1. V Home Assistant otvor **Nastavenia → Doplnky → Obchod s doplnkami**.
2. Vpravo hore **⋮ → Repozitáre** a pridaj `https://github.com/michalgabor/hass-repo`.
3. Nájdi doplnok **Pocket Agents** a nainštaluj ho (obraz sa zostaví lokálne,
   chvíľu to trvá).
4. Spusti doplnok. Kým nie je prihlásenie, agenti v logu len vyzývajú na `agent-setup`.

## Prvé nastavenie

1. Otvor panel **Pocket Agents** v bočnom menu (webový terminál).
2. Spusti:

   ```sh
   agent-setup
   ```

   - Ak ešte nie si prihlásený, spustí sa `claude auth login`. Zvoľ prihlásenie
     cez claude.ai, otvor odkaz v prehliadači a vlož kód späť do terminálu.
   - Potom sa pre každého agenta v `/config/agents/*/` spustí
     `claude remote-control --spawn session --no-create-session-in-dir`.
     Potvrď **trust adresára** (`y`) a povolenie Remote Control. Keď server
     beží, ukonči ho **Ctrl+C** — skript pokračuje ďalším agentom.
3. **Reštartuj doplnok.** Agenti sa spustia ako služby a objavia sa v Claude
   appke v zozname sessions (názov podľa `title`, automaticky generované
   sessions majú prefix podľa `name`).

Prihlásenie a trust sa ukladajú do `/data` doplnku, takže prežijú reštart
aj aktualizáciu.

## Konfigurácia

```yaml
agents:
  - name: hass                 # ^[a-z0-9][a-z0-9-]{0,30}$, zároveň názov adresára
    title: Home Assistant      # názov session v appke (predvolene name)
    permission_mode: default   # default | acceptEdits | plan
    spawn: same-dir            # same-dir | worktree | session
    capacity: 4                # 1–32, max. súbežných sessions (nie pri spawn: session)
    enabled: true              # false = agent sa nespustí
secrets:
  - name: HASS_TOKEN           # ^[A-Z_][A-Z0-9_]*$
    value: "eyJ..."            # exportuje sa ako premenná prostredia pre všetkých agentov
```

- `spawn: same-dir` – všetky sessions zdieľajú adresár agenta.
- `spawn: worktree` – každá nová session dostane vlastný git worktree; adresár
  agenta musí byť git repozitár (s aspoň jedným commitom).
- `spawn: session` – jedna session, ďalšie pripojenia sa odmietnu.
- `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN` a `CLAUDE_CODE_OAUTH_TOKEN`
  v `secrets` sa ignorujú, pretože by Remote Control vypli.

## Pridanie agenta

1. V konfigurácii doplnku pridaj do `agents` novú položku, napr.:

   ```yaml
   - name: energia
     title: Energia
     permission_mode: plan
   ```

2. Ulož a reštartuj doplnok – vytvorí sa `/config/agents/energia/` so šablónou
   `CLAUDE.md`, prázdnym `.mcp.json` a `.claude/skills/`. Existujúce súbory sa
   nikdy neprepisujú.
3. V paneli spusti znova `agent-setup` (potvrdíš trust nového adresára;
   pri už potvrdených agentoch len stlač Ctrl+C) a doplnok ešte raz reštartuj.
4. Uprav `CLAUDE.md`, `.mcp.json` a skills agenta – v paneli
   (`cd /config/agents/energia`) alebo cez Samba / File editor v
   `/addon_configs/<repo>_pocket_agents/agents/energia/`.

## Príklad `.mcp.json` pre Home Assistant MCP

Na Home Assistant zapni integráciu **Model Context Protocol Server**, vytvor
long-lived access token (Profil → Zabezpečenie) a ulož ho do `secrets` ako
`HASS_TOKEN`. Potom do `/config/agents/hass/.mcp.json`:

```json
{
  "mcpServers": {
    "home-assistant": {
      "type": "http",
      "url": "http://homeassistant:8123/api/mcp",
      "headers": {
        "Authorization": "Bearer ${HASS_TOKEN}"
      }
    }
  }
}
```

Claude Code pri načítaní `.mcp.json` dosadí `${HASS_TOKEN}` z prostredia.
Pri prvom použití projektového MCP servera sa ťa môže opýtať na schválenie.

## Aktualizácia Claude Code

Obraz sa zostavuje s `@anthropic-ai/claude-code@latest` a automatické
aktualizácie sú vypnuté (`DISABLE_AUTOUPDATER=1`). Novú verziu Claude Code
dostaneš tak, že v `pocket_agents/config.yaml` zvýšiš `version`
(napr. `1.0.0` → `1.0.1`), pushneš zmenu a v HA klikneš na **Aktualizovať** –
Supervisor obraz zostaví nanovo a stiahne aktuálny Claude Code.
Konkrétnu verziu môžeš pripnúť cez `CLAUDE_VERSION` v `build.yaml`.

## Logy

Výstup každého agenta je v logu doplnku s prefixom `[name]`. Ak
`claude remote-control` skončí, služba počká 30 s a s6 ju spustí znova.
