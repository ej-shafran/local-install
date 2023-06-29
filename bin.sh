#!/usr/bin/env bash

SCRIPT_NAME="$(basename "$0")"

SCRIPT_ARGS=()

KEEP_TAR=0

spin() {
  local cmd="$*"

  eval "$cmd 2>/dev/null >/dev/null" &

  local pid="$!"
  local i=0
  while [ -d "/proc/$pid" ]; do
    if [ "$i" -lt 103 ]; then
      i=$((i + RANDOM % 10 + 1))
      show_progress "$i" 111
      sleep 0.7
    fi
  done
  show_progress 111 111
}

usage() {
  echo ""
  echo -e "$SCRIPT_NAME - pack and install a local NPM package"
  echo ""
  echo "Usage: $SCRIPT_NAME [-k] [path]"
  echo ""
  echo "Options:"
  echo -e "\t-h --help      Show this message"
  echo -e "\t-k --keep-tar  Don't delete the \`.tar\` file after packing"
}

exit_abnormal() {
  usage
  exit 1
}

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

info() {
  printf "\r  [ \033[00;34mINFO\033[0m ] %b" "$1"
}

BAR_SIZE=40
BAR_CHAR_DONE="#"
BAR_CHAR_TODO="-"
BAR_PERCENTAGE_SCALE=2

show_progress() {
    current="$1"
    total="$2"

    # calculate the progress in percentage 
    percent=$(bc <<< "scale=$BAR_PERCENTAGE_SCALE; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $BAR_SIZE * $percent / 100" )
    todo=$(bc <<< "scale=0; $BAR_SIZE - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${BAR_CHAR_DONE}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${BAR_CHAR_TODO}")

    # output the bar
    info "packing: [${done_sub_bar}${todo_sub_bar}] ${percent}%"
}


query_user() {
  printf "\r  [ \033[0;33m?\033[0m ] %b" "$1"
}

success() {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %b\n" "$1"
}

fail() {
  printf "\r\033[2K  [ \033[0;31mFAIL\033[0m ] %b\n" "$1"
  exit
}

main() {
  check "$@"

  path="${SCRIPT_ARGS[0]}"

  if [ -z "$path" ]; then
    query_user "Enter the path to pack and install:\n"
    read -re path
    echo ""
  fi

  package_json="$path/package.json"

  if ! [ -f "$package_json" ]; then
    fail "no package.json found in $path"
    exit 1
  fi

  package_name=$(sed -nr '/"name":/ s/.*"name": "(.+)",.*/\1/p' "$package_json")
  parsed_name=${package_name/\@/}
  version=$(sed -nr '/"version":/ s/.*"version": "(.+)",.*/\1/p' "$package_json")
  file_name="${parsed_name//\//-}-$version.tgz"
  
  set -e
  
  info "packing $path into $file_name\n"
  spin npm pack "$path"

  echo "\n"
  info "installing dependencies, along with $package_name...\n"
  npm i "$file_name" 2>/dev/null | while read -r line; do
    info "$line\n"
  done

  if [ "$KEEP_TAR" -eq 0 ]; then
    echo ""
    info "removing $file_name...\n"
    rm "$file_name"
  fi

  echo ""
  success "Done!"
}

ctrl_c() {
  if [ "$KEEP_TAR" -eq 0 ] && [ "$file_name" ] && [ -f "$file_name" ]; then
    rm "$file_name"
  fi
}

trap ctrl_c INT

main "$@"
