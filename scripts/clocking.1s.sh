#!/bin/bash
#
# This script is loaded using BitBar (https://getbitbar.com/)
#
# It creates a menu bar item on macOS displaying currently clocking
# task, with action buttons to clock out and mark current item as
# done.

emacs_exec() {
  /usr/local/bin/emacsclient \
    --eval "$1" \
    || echo "${2:-}"
}

clocking_p() {
  [ "$(emacs_exec "(org-clocking-p)")" = "t" ]
}

clocking_text() {
  emacs_exec "(substring-no-properties (org-clock-get-clock-string))" | \
    sed -e 's/^\s+//g' -e 's/\s+$//g' -e 's/^" //' -e 's/"$//' | \
    sed -e 's/(\(.*\))/\1/' | \
    sed -e 's/^/:clock3:/' -e 's/$/|color=green/'
}

clocking_menu() {
  clocking_text
  echo "---"
  echo ":no_entry_sign: Clock out|terminal=false bash=$0 param1=clock_out"
  echo ":white_check_mark: Done and clock out|terminal=false bash=$0 param1=done_and_clock_out"
  echo "---"
  echo "Open Emacs|terminal=false bash=$0 param1=open_emacs"
}

non_clocking_menu() {
  echo "No clocking task"
  echo "---"
  echo "Open Emacs|terminal=false bash=$0 param1=open_emacs"
}

bitbar_show_menu() {
  if clocking_p; then
    clocking_menu
  else
    non_clocking_menu
  fi
}

case "$1" in
  clock_out)
    emacs_exec "(org-clock-out)"
    ;;

  done_and_clock_out)
    emacs_exec "(shou/mark-clocking-task-as-done)"
    ;;

  open_emacs)
    open -a "Emacs.app"
    ;;

  *)
    bitbar_show_menu
esac
