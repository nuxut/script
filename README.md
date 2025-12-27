# Nuxut Script

The automated installer and configuration bootstrapper for the Nuxut environment (Hyprland + Nuxut Shell).

## Installation

Run the following command to install the full environment:
```bash
curl -s https://raw.githubusercontent.com/nuxut/script/main/setup.sh | bash
```

**What this does:**
1.  Bootstraps the installation environment in `~/.cache/nuxut-script`.
2.  Installs core drivers (NVIDIA/AMD), Hyprland, and essential apps.
3.  Applies system themes, cosmetics, and cursors.
4.  Installs and configures **Nuxut Shell**.
5.  Starts Hyprland.
