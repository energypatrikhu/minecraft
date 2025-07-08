# Minecraft Server Management

This project provides a flexible Docker Compose-based setup for running various Minecraft server types (CurseForge, FTB, Fabric, NeoForge, etc.) with optional backup support and easy mod management.

This project is based on the [itzg/minecraft-server](https://github.com/itzg/docker-minecraft-server) and the [itzg/mc-backup](https://github.com/itzg/docker-mc-backup).

---

## Environments

- **Default Environment Files:**
  - Located in `configs/` (e.g., `configs/curseforge_2025-02-16_all-the-mods-10.env`)
  - Each server has its own `.env` file. The filename format is:

    ```
    <platform>_<YYYY-MM-DD>_<modpack-or-server-name>.env
    ```

    Example: `curseforge_2025-02-16_all-the-mods-10.env`

- **Changeable Variables:**
  - Most variables in the `.env` files can be changed to suit your needs (e.g., `SERVER_NAME`, `WHITELIST`, `OPS`, `BACKUP`, etc.).
  - See `configs/examples/` for template files for each platform.
  - For more environment variables checkout the files located in `env/`.

---

## CurseForge API Key

- To download mods from CurseForge, you **must** set up your API key:
  - Copy `secrets/curseforge_api_key.txt.example` to `secrets/curseforge_api_key.txt` and add your key.

---

## Example Server Config

- **Filename Structure:**
  - `configs/<platform>_<date>_<name>.env`
- **Example Content:**

    ```ini
    # configs/curseforge_2025-02-16_all-the-mods-10.env.example
    CREATED_AT = 2025-02-16
    SERVER_NAME = All The Mods 10
    MODPACK_NAME = all-the-mods-10
    MODPACK_VERSION = 2.39
    MEMORY = 6G
    JAVA_VERSION = 21
    BACKUP = true
    WHITELIST = player1, player2
    OPS = player1
    # ... other variables ...
    ```

---

## Enabling Backups

- To enable the backup container, set `BACKUP = true` in your server's `.env` file.
- To disable backups, either omit the `BACKUP` variable or set `BACKUP = false`.
- The backup container will create backups in the `/opt/minecraft-backups/<platform>_<date>_<name>/` directory. (the base directory can be changed in the `mc.sh` script by changing the variable `__dcf_mc__backup_dir`)

---

## Directory Structure

- **Default Directories:**
  - Server data: `/opt/minecraft-servers/<platform>_<date>_<name>/`
    > Can be changed in `mc.sh` by changing the variable `__dcf_mc__server_dir`
  - Configs: `configs/`
  - Compose files: `compose/`
  - Platform configs: `platforms/`
  - Secrets: `secrets/`
  - Backups: `/opt/minecraft-backups`
    > Can be changed in `mc.sh` by changing the variable `__dcf_mc__backup_dir`

---

## Platform Configs

- Platform-specific Docker Compose and config files are in `compose/` and `platforms/`.
- Example Compose files:
  - `compose/docker-compose.base.yml` (no backup)
  - `compose/docker-compose.full.yml` (with backup)

---

## Server Location

- Each server runs in its own directory under `/opt/minecraft-servers/` (e.g., `/opt/minecraft-servers/fabric_2025-07-05_bingo/`).

---

## Whitelist, Ops, and Players

- **Whitelist:**
  - Controlled by the `WHITELIST` variable in the `.env` file, by default it is empty.
  - To enable, list players in `WHITELIST`. (e.g., `WHITELIST = player1, player2`).
- **Opped Players:**
  - Set via the `OPS` variable (comma-separated list).

---

## Adding Mods

- **CurseForge:**
  - Requires a valid API key in `secrets/curseforge_api_key.txt`.
  - List mods in the `CURSEFORGE_MODS` variable in your `.env` file.
- **Modrinth:**
  - Supported via the `MODRINTH_MODS` variable as well.

---

## Timezone

- To change the timezone, edit or create `env/.tz.env` and set the `TZ` variable (e.g., `TZ=Europe/Berlin`).

---

## Setting Up a Server (Example)

1. Copy an example config from `configs/examples/`:

    ```sh
    cp configs/examples/@example.curseforge.env configs/curseforge_2025-02-16_all-the-mods-10.env
    # Edit the new file as needed
    ```
2. Set up your CurseForge API key if using CurseForge mods.
3. Start the server:

    ```sh
    ./mc.sh curseforge_2025-02-16_all-the-mods-10
    ```

---

For more details, see comments in the example config files and the `mc.sh` script.
