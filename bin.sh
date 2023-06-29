#!/usr/bin/env bash

# SETTINGS

trap handle_keyboard_interrupt INT
set -e

# GLOBALS

SCRIPT_NAME="$(basename "$0")"
SCRIPT_ARGS=()
KEEP_TAR=0
FILE_NAME=

# UTILITY FUNCTIONS

formatted() {
  echo -en "\x1b[33m$1\x1b[0m"
}

info() {
  printf "\r  [ \033[00;34mINFO\033[0m ] %b" "$1"
}

query_user() {
  printf "\r  [ \033[0;33m?\033[0m ] %b\n" "$1"
}

success() {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %b\n" "$1"
}

fail() {
  printf "\r\033[2K  [ \033[0;31mFAIL\033[0m ] %b\n" "$1"
  exit
}

exit_abnormal() {
  usage
  exit 1
}

# LOADING UTILITIES

progress_bar() {
    local current="$1"
    local total="$2"

    local bar_size=40
    local bar_char_done="#"
    local bar_char_todo="-"
    local bar_percentage_scale=2

    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )

    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    done_sub_bar=$(printf "%${done}s" | tr " " "$bar_char_done")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "$bar_char_todo")

    info "npm pack [$done_sub_bar$todo_sub_bar] $percent%"
}


load() {
  local cmd="$*"

  eval "$cmd 2>/dev/null >/dev/null" &

  local pid="$!"
  local i=0

  while [ -d "/proc/$pid" ]; do
    if [ "$i" -lt 103 ]; then
      i=$((i + RANDOM % 10 + 1))
      progress_bar "$i" 111
      sleep 0.7
    fi
  done

  progress_bar 111 111
  echo ""
}

# USAGE

usage() {

cat << EOF
$SCRIPT_NAME - pack and install a local NPM package

Usage: $SCRIPT_NAME [-k] [path]

Options:
  -h --help      Show this message
  -k --keep-tar  Don't delete the \`tgz\` file after packing
EOF

}

# PARSE OPTIONS

check_long_opt() {
  arg="$1"

  case "$arg" in
    help)
      usage
      exit 0
      ;;
    keep-tar)
      KEEP_TAR=1
      ;;
    *)
      exit_abnormal
      ;;
  esac
}

check() {
  while [ $OPTIND -le "$#" ]; do
      if getopts ':kh-:' option
      then
          case $option
          in
            -)
              check_long_opt "$OPTARG"
              ;;
            h) 
              usage
              exit 0
              ;;
            k)
              KEEP_TAR=1
              ;;
            ?)
              exit_abnormal
              ;;
          esac
      else
          SCRIPT_ARGS+=("${!OPTIND}")
          ((OPTIND++))
      fi
  done
}

# HANDLE KEYBOARD INTERRUPT

handle_keyboard_interrupt() {
  if [ "$KEEP_TAR" -eq 0 ] && [ "$FILE_NAME" ] && [ -f "$FILE_NAME" ]; then
    rm "$FILE_NAME"
  fi
}

# MAIN

main() {
  check "$@"

  local path
  path="${SCRIPT_ARGS[0]}"

  if [ -z "$path" ]; then
    query_user "enter the path to pack and install:\n"
    read -re path
    echo ""
  fi

  local package_json
  package_json="$path/package.json"

  if ! [ -f "$package_json" ]; then
    fail "no package.json found in $(formatted "\"$path\"")"
    exit 1
  fi

  local package_name
  local parsed_name
  local version

  package_name=$(sed -nr '/"name":/ s/.*"name": "(.+)",.*/\1/p' "$package_json")
  parsed_name=${package_name/\@/}
  version=$(sed -nr '/"version":/ s/.*"version": "(.+)",.*/\1/p' "$package_json")

  FILE_NAME="${parsed_name//\//-}-$version.tgz"
  
  info "packing $(formatted "\"$path\"") into $(formatted "\"$FILE_NAME\"")\n"
  load npm pack "$path"

  echo ""
  info "installing dependencies, along with $(formatted "$package_name")\n"
  npm install --color=always "$FILE_NAME" 2>&1 | while read -r line; do
    info "$line\n"
  done

  if [ "$KEEP_TAR" -eq 0 ]; then
    echo ""
    info "removing $(formatted "\"$FILE_NAME\"")...\n"
    rm "$FILE_NAME"
  fi

  echo ""
  success "done!"
}

main "$@"
