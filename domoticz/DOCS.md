# Use
Makes a Domoticz instance available as a HomeAssistant add-on. Domoticz (UI interface) is accessible via HA Ingress Controller. In this case Domoticz has deactivated authorization because authorization is applied on HA Ingress Controller.

# Configuration
It is possible to set the forwarding of port 8080 (UI interface).

# Persistent data
- Database is stored in the add-on data directory (`/data/domoticz.db`).
- Domoticz userdata (dzVents/Lua scripts, Python plugins, `customstart.sh`) is stored in the add-on config folder, visible in Home Assistant as `/addon_configs/<repo-id>_<slug>/` (e.g. via the Samba or File editor add-on).


# Credits
This addon is Domoticz's docker [image](https://hub.docker.com/r/domoticz/domoticz) packaged as a Home Assistant addon.
