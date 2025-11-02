#!/bin/bash
# check-dependencies.sh
# Auto-install required dependencies for spec-drive workflows

set -eo pipefail

# Detect OS
detect_os() {
  case "$(uname -s)" in
    Darwin*) echo "macos" ;;
    Linux*)  echo "linux" ;;
    *)       echo "unknown" ;;
  esac
}

OS="$(detect_os)"

# Install yq based on OS
install_yq() {
  echo "📦 Installing yq..."

  case "$OS" in
    macos)
      if command -v brew &>/dev/null; then
        brew install yq
      else
        echo "❌ ERROR: Homebrew not found. Please install Homebrew first:" >&2
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" >&2
        return 1
      fi
      ;;
    linux)
      # Try to install via common package managers
      if command -v apt-get &>/dev/null; then
        echo "  Using apt-get..."
        sudo apt-get update -qq && sudo apt-get install -y yq
      elif command -v yum &>/dev/null; then
        echo "  Using yum..."
        sudo yum install -y yq
      elif command -v snap &>/dev/null; then
        echo "  Using snap..."
        sudo snap install yq
      else
        echo "❌ ERROR: No supported package manager found (apt-get, yum, snap)" >&2
        echo "  Manual install: https://github.com/mikefarah/yq#install" >&2
        return 1
      fi
      ;;
    *)
      echo "❌ ERROR: Unsupported OS for auto-install" >&2
      echo "  Manual install: https://github.com/mikefarah/yq#install" >&2
      return 1
      ;;
  esac

  echo "✓ yq installed successfully"
  return 0
}

# Install python3 based on OS
install_python3() {
  echo "📦 Installing python3..."

  case "$OS" in
    macos)
      if command -v brew &>/dev/null; then
        brew install python3
      else
        echo "❌ ERROR: Homebrew not found. Please install Homebrew first:" >&2
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" >&2
        return 1
      fi
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        echo "  Using apt-get..."
        sudo apt-get update -qq && sudo apt-get install -y python3
      elif command -v yum &>/dev/null; then
        echo "  Using yum..."
        sudo yum install -y python3
      else
        echo "❌ ERROR: No supported package manager found" >&2
        echo "  Manual install: https://www.python.org/downloads/" >&2
        return 1
      fi
      ;;
    *)
      echo "❌ ERROR: Unsupported OS for auto-install" >&2
      echo "  Manual install: https://www.python.org/downloads/" >&2
      return 1
      ;;
  esac

  echo "✓ python3 installed successfully"
  return 0
}

# Check and install if needed
echo "🔍 Checking dependencies..."

# Check python3
if ! command -v python3 &>/dev/null; then
  echo "  python3: NOT FOUND"
  if ! install_python3; then
    echo "" >&2
    echo "❌ FATAL: Failed to install python3" >&2
    exit 1
  fi
else
  echo "  python3: ✓ $(python3 --version 2>&1 | head -1)"
fi

# Check yq
if ! command -v yq &>/dev/null; then
  echo "  yq: NOT FOUND"
  if ! install_yq; then
    echo "" >&2
    echo "❌ FATAL: Failed to install yq" >&2
    exit 1
  fi
else
  echo "  yq: ✓ $(yq --version 2>&1 | head -1)"
fi

# Check git (optional)
if ! command -v git &>/dev/null; then
  echo "  git: ⚠️  NOT FOUND (optional, recommended for version control)"
else
  echo "  git: ✓ $(git --version 2>&1 | head -1)"
fi

echo ""
echo "✅ All required dependencies available"
exit 0
