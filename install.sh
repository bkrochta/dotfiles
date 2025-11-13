#!/usr/bin/env bash
set -euo pipefail

# Check that zsh is installed
if [ ! -x "$(command -v zsh)" ]; then
    echo "zsh is not installed. Exiting..."
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DOTFILES_DIR/zsh"
TARGET="$HOME/.zsh"

# Create symbolic link for zsh configuration if needed
if [ -L "$TARGET" ]; then
    CURRENT_LINK="$(readlink "$TARGET")"
    if [ "$CURRENT_LINK" = "$SRC" ]; then
        echo "Symlink $TARGET already points to $SRC. Skipping."
    else
        echo "Symlink $TARGET exists and points to $CURRENT_LINK. Repointing to $SRC."
        rm "$TARGET"
        ln -s "$SRC" "$TARGET"
        echo "Updated symlink $TARGET -> $SRC"
    fi
elif [ -e "$TARGET" ]; then
    echo "$TARGET already exists and is not a symlink. Skipping creating symlink."
else
    ln -s "$SRC" "$TARGET"
    echo "Created symlink $TARGET -> $SRC"
fi

# Ensure history file exists (only when target is usable)
if [ -L "$TARGET" ] || [ -d "$TARGET" ]; then
    touch "$TARGET/history"
    echo "Ensured $TARGET/history exists."
else
    if [ -e "$TARGET" ] && [ ! -d "$TARGET" ]; then
        echo "$TARGET exists and is not a directory; skipping history creation."
    else
        mkdir -p "$TARGET"
        touch "$TARGET/history"
        echo "Created $TARGET and ensured history file exists."
    fi
fi

# Add source command to .zshrc if not already presentel
ZSHRC="$HOME/.zshrc"
LINE="source ~/.zsh/zshrc"
if [ -f "$ZSHRC" ]; then
    if ! grep -qxF "$LINE" "$ZSHRC"; then
        echo "$LINE" >> "$ZSHRC"
        echo "Appended source command to $ZSHRC"
    else
        echo "Source command already present in $ZSHRC. Skipping."
    fi
else
    echo "$LINE" > "$ZSHRC"
    echo "Created $ZSHRC and added source command."
fi

# Change default shell to zsh if not already set
ZSH_PATH="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$(whoami)" | cut -d: -f7 2>/dev/null || echo "$SHELL")"
if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    # Try non-interactive chsh; if it fails, inform the user
    if chsh -s "$ZSH_PATH" "$(whoami)" 2>/dev/null; then
        echo "Default shell changed to $ZSH_PATH"
    elif chsh -s "$ZSH_PATH" 2>/dev/null; then
        echo "Default shell changed to $ZSH_PATH"
    else
        echo "Unable to change shell non-interactively. Run:"
        echo "  chsh -s $ZSH_PATH"
    fi
else
    echo "Default shell is already $ZSH_PATH. Skipping."
fi