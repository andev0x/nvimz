# Platform detection utilities

detect_os() {
  case "${OSTYPE}" in
    darwin*) OS="macos" ;;
    linux*)
      if [[ -f /etc/arch-release ]]; then
        OS="arch"
      elif [[ -f /etc/debian_version ]]; then
        OS="ubuntu"
      else
        OS="linux"
      fi
      ;;
    *) OS="unknown" ;;
  esac
  export OS
}
