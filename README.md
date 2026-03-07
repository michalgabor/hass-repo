# Home Assistant Blueprints

Kolekcia Home Assistant blueprintov pre domácu automatizáciu.

---

## Vitae – Nastav režim (Script Blueprint)

Ovládanie biodynamickej žiarovky [Vitae](https://www.vitaelight.com) cez smart zásuvku.

### Ako to funguje

Vitae je 3-režimová žiarovka bez Wi-Fi – režimy sa prepínajú vypínaním napájania:

| Režim | Výkon | Farba | Použitie |
|-------|-------|-------|----------|
| Noc | 2W | Oranžová 1200K (bez modrej) | 90 min pred spaním |
| Večer | 6W | Teplá biela 2800K | Relaxácia, čítanie |
| Deň | 7W | Jasná biela 4000K | Práca, koncentrácia |

**Logika reset:**
- Vypnutá **>11 sekúnd** → vždy Noc (reset)
- Vypnutá **<11 sekúnd** → posun na ďalší krok

### Požiadavky

- Home Assistant 2024.6+
- Smart zásuvka integrovaná v HA (Zigbee, Z-Wave, Wi-Fi)

### Inštalácia

[![Open your Home Assistant instance and show the blueprint import dialog.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https://github.com/michalgabor/ha-blueprint/blob/main/blueprints/script/vitae_mode_blueprint.yaml)

Alebo manuálne: **Settings → Blueprints → Import Blueprint** a vlož URL:

```
https://github.com/michalgabor/ha-blueprint/blob/main/blueprints/script/vitae_mode_blueprint.yaml
```
