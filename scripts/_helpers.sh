#!/bin/bash

# Progress helpers
mark_running() {
  local stage="$1"
  [[ -f "$PROGRESS_FILE" ]] || return 0
  sed -i "s/^$stage=.*/$stage=running/" "$PROGRESS_FILE"
}

mark_done() {
  local stage="$1"
  [[ -f "$PROGRESS_FILE" ]] || return 0
  sed -i "s/^$stage=.*/$stage=done/" "$PROGRESS_FILE"
}

mark_failed() {
  local stage="$1"
  [[ -f "$PROGRESS_FILE" ]] || return 0
  sed -i "s/^$stage=.*/$stage=failed/" "$PROGRESS_FILE"
}
