# Pocket Agents

A Home Assistant add-on that runs multiple **Claude Code Remote Control** servers
("agents"). Each agent runs in its own directory `/addon_configs/<repo>_pocket_agents/agents/<name>/`
(`/config/agents/<name>/` inside the container) with its own `CLAUDE.md`, `.mcp.json`
and `.claude/skills/`. You control the agents from the Claude mobile app or from
[claude.ai/code](https://claude.ai/code).

> Remote Control requires a Claude Pro, Max, Team or Enterprise subscription
> and a claude.ai sign-in. API keys do not work.

## Installation

1. In Home Assistant open **Settings → Add-ons → Add-on Store**.
2. Top right **⋮ → Repositories** and add `https://github.com/michalgabor/hass-repo`.
3. Find the **Pocket Agents** add-on and install it (the image is built locally,
   which takes a while).
4. Start the add-on. Until you sign in, the agents only log a prompt to run `agent-setup`.

## First-time setup

1. Open the **Pocket Agents** panel in the sidebar (web terminal).
2. Run:

   ```sh
   agent-setup
   ```

   - If you are not signed in yet, `claude auth login` starts. Choose the
     claude.ai sign-in, open the link in a browser and paste the code back
     into the terminal.
   - Then, for each agent in `/config/agents/*/`, it runs
     `claude remote-control --spawn session --no-create-session-in-dir`.
     Confirm **directory trust** (`y`) and Remote Control. Once the server is
     running, stop it with **Ctrl+C** and the script continues with the next agent.
3. **Restart the add-on.** The agents start as services and appear in the
   session list in the Claude app (named after `title`; auto-generated
   sessions are prefixed with `name`).

The sign-in and trust decisions are stored in the add-on's `/data`, so they
survive restarts and updates.

## Configuration

```yaml
agents:
  - name: hass                 # ^[a-z0-9][a-z0-9-]{0,30}$, also the directory name
    title: Home Assistant      # session name in the app (defaults to name)
    permission_mode: default   # default | acceptEdits | plan
    spawn: same-dir            # same-dir | worktree | session
    capacity: 4                # 1–32, max concurrent sessions (not with spawn: session)
    enabled: true              # false = the agent is not started
secrets:
  - name: HASS_TOKEN           # ^[A-Z_][A-Z0-9_]*$
    value: "eyJ..."            # exported as an environment variable for all agents
```

- `spawn: same-dir` – all sessions share the agent's directory.
- `spawn: worktree` – every new session gets its own git worktree; the agent's
  directory must be a git repository (with at least one commit).
- `spawn: session` – a single session; further connections are rejected.
- `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN` and `CLAUDE_CODE_OAUTH_TOKEN`
  in `secrets` are ignored because they would disable Remote Control.

## Adding an agent

1. Add a new entry to `agents` in the add-on configuration, e.g.:

   ```yaml
   - name: energy
     title: Energy
     permission_mode: plan
   ```

2. Save and restart the add-on – this creates `/config/agents/energy/` with a
   template `CLAUDE.md`, an empty `.mcp.json` and `.claude/skills/`. Existing
   files are never overwritten.
3. Run `agent-setup` in the panel again (to confirm trust for the new
   directory; for agents you already confirmed just press Ctrl+C) and restart
   the add-on once more.
4. Edit the agent's `CLAUDE.md`, `.mcp.json` and skills – in the panel
   (`cd /config/agents/energy`) or via Samba / File editor in
   `/addon_configs/<repo>_pocket_agents/agents/energy/`.

## Example `.mcp.json` for the Home Assistant MCP server

In Home Assistant enable the **Model Context Protocol Server** integration,
create a long-lived access token (Profile → Security) and store it in
`secrets` as `HASS_TOKEN`. Then put this in `/config/agents/hass/.mcp.json`:

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

Claude Code expands `${HASS_TOKEN}` from the environment when it loads
`.mcp.json`. It may ask you to approve the project MCP server the first time
it is used.

## Updating Claude Code

The image is built with `@anthropic-ai/claude-code@latest` and auto-updates
are disabled (`DISABLE_AUTOUPDATER=1`). To get a new Claude Code version, bump
`version` in `pocket_agents/config.yaml` (e.g. `1.0.0` → `1.0.1`), push the
change and click **Update** in HA – the Supervisor rebuilds the image and
installs the current Claude Code. You can pin a specific version via
`CLAUDE_VERSION` in `build.yaml`.

## Logs

Each agent's output appears in the add-on log prefixed with `[name]`. If
`claude remote-control` exits, the service waits 30 s and s6 starts it again.
