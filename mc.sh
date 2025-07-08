#!/bin/bash

__dcf_mc__project_base="/opt/minecraft"
__dcf_mc__compose_base="$__dcf_mc__project_base/compose"
__dcf_mc__config_env_base="$__dcf_mc__project_base/configs"

__dcf_mc__server_dir="/opt/minecraft-servers"
__dcf_mc__backup_dir="/opt/minecraft-backups"

__dcf-mc-get-env-value() {
  local config_env="$1"
  local var_name="$2"
  grep -iE "^$var_name\s*=" "$config_env" | sed -E "s/^$var_name\s*=\s*//I; s/[[:space:]]*$//"
}
__dcf-mc-get-java-type() {
  local config_env="$1"
  local java_version=$(__dcf-mc-get-env-value "$config_env" "JAVA_VERSION")

  # if version 8 use "graalvm-ce"
  # else use "graalvm"
  if [[ "$java_version" == "8" ]]; then
    echo "graalvm-ce"
  else
    echo "graalvm"
  fi
}
__dcf-mc-set-flags() {
  local config_env="$1"
  local tmp_env_file="$2"
  local java_version=$(__dcf-mc-get-env-value "$config_env" "JAVA_VERSION")

  # If JAVA_VERSION < 17 use AIKAR, else use MEOWICE flags
  if [[ "$java_version" -lt 17 ]]; then
    echo "USE_AIKAR_FLAGS = true" >>"$tmp_env_file"
  else
    echo "USE_MEOWICE_FLAGS = true" >>"$tmp_env_file"
    echo "USE_MEOWICE_GRAALVM_FLAGS = true" >>"$tmp_env_file"
  fi
}
__dcf-mc-get-backup-enabled() {
  local config_env="$1"
  local backup_enabled=$(__dcf-mc-get-env-value "$config_env" "BACKUP")
  if [[ "${backup_enabled,,}" == "true" ]]; then
    echo "true"
  else
    echo "false"
  fi
}
__dcf-mc() {
  local file_basename=$(basename -- "$1")
  file_basename="${file_basename%.env}"
  local server_type=$(echo "$file_basename" | awk -F'_' '{print $1}')
  local project_name="mc_$file_basename"
  local compose_file_base="$__dcf_mc__compose_base/docker-compose.base.yml"
  local compose_file_full="$__dcf_mc__compose_base/docker-compose.full.yml"
  local config_env="$__dcf_mc__config_env_base/$file_basename.env"
  local java_type=$(__dcf-mc-get-java-type "$config_env")
  local backup_enabled=$(__dcf-mc-get-backup-enabled "$config_env")

  if [[ ! -f "$config_env" ]]; then
    echo "Error: Environment file $config_env does not exist."
    return 1
  fi

  # create a tmp env file with the JAVA_TYPE variable
  local tmp_env_file=$(mktemp)
  echo "SERVER_TYPE = $server_type" >>"$tmp_env_file"
  echo "SERVER_DIR = $__dcf_mc__server_dir" >>"$tmp_env_file"
  echo "JAVA_TYPE = $java_type" >>"$tmp_env_file"
  __dcf-mc-set-flags "$config_env" "$tmp_env_file"

  echo -e "Starting Minecraft Server"
  if [[ "$backup_enabled" == "true" ]]; then
    echo "BACKUP_DIR = $__dcf_mc__backup_dir" >>"$tmp_env_file"
    echo -e "> Backup is enabled"
  else
    echo -e "> Backup is disabled"
  fi

  echo -e "> Environment Variables:"
  if [[ -s "$config_env" ]]; then
    grep -v '^[[:space:]]*#' "$config_env" | grep -E '^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=' | while IFS= read -r line; do
      echo "  - $line"
    done
  else
    echo "  (No variables in $config_env)"
  fi
  if [[ -s "$tmp_env_file" ]]; then
    grep -v '^[[:space:]]*#' "$tmp_env_file" | grep -E '^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=' | while IFS= read -r line; do
      echo "  - $line"
    done
  else
    echo "  (No variables in $tmp_env_file)"
  fi

  if [[ "$backup_enabled" == "true" ]]; then
    if [[ ! -f "$compose_file_full" ]]; then
      echo "Error: Docker Compose file $compose_file_full does not exist."
      return 1
    fi

    docker compose -p "$project_name" \
      --env-file "$tmp_env_file" \
      --env-file "$config_env" \
      -f "$compose_file_full" \
      up -d
  else
    if [[ ! -f "$compose_file_base" ]]; then
      echo "Error: Docker Compose file $compose_file_base does not exist."
      return 1
    fi

    docker compose -p "$project_name" \
      --env-file "$tmp_env_file" \
      --env-file "$config_env" \
      -f "$compose_file_base" \
      up -d
  fi

  # clean up the tmp env file
  rm -f "$tmp_env_file"
}

__dcf-mc-autocomplete() {
  local cur opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  opts=$*

  mapfile -t COMPREPLY < <(compgen -W "${opts}" -- "${cur}")
}
__dcf-mc-get-configs() {
  find "$__dcf_mc__config_env_base" -type f -name "*.env" -not \( -name "@*" \) -printf '%f\n' | sed 's/\.env$//'
}
__dcf-mc-list-configs() {
  __dcf-mc-autocomplete "$(__dcf-mc-get-configs "$1")"
}
__dcf-mc-display-help() {
  echo "Usage: mc <server>"
  echo "Available servers:"
  __dcf-mc-get-configs $1 | sed 's/^/  /'
}

mc() {
  if [[ -z "$1" ]]; then
    __dcf-mc-display-help
    return 1
  fi

  __dcf-mc "$1"
}
complete -F __dcf-mc-list-configs mc

mc.help() {
  echo "+---------+--------------------------------------+"
  echo "| mc.help | Minecraft commands (This command)    |"
  echo "+---------+--------------------------------------+"
  echo "| mc      | Start Minecraft Server (mc <server>) |"
  echo "+---------+--------------------------------------+"
}
