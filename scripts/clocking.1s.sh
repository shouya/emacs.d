#!/bin/bash
#
# This script is loaded using BitBar (https://getbitbar.com/)
#
# It creates a menu bar item on macOS displaying currently clocking
# task, with action buttons to clock out and mark current item as
# done.

# for jq
PATH="$HOME/.nix-profile/bin:/usr/local/bin:$PATH"

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
    jq -r . | \
    sed -e 's/^ //' -e 's/(\(.*\))/\1/' | \
    sed -e 's/^/:clock3:/' -e 's/$/|color=green/'
}

clocking_menu() {
  clocking_text
  echo "---"
  echo ":soon: Clock out (TODO)|terminal=false bash=$0 param1=clock_out"
  echo ":on: Clock out (IN-PROG)|terminal=false bash=$0 param1=simply_clock_out"
  echo ":end: Clock out (DONE)|terminal=false bash=$0 param1=done_and_clock_out"
  echo "---"
  echo "Open Emacs|terminal=false bash=$0 param1=open_emacs"
}

non_clocking_menu() {
  echo "No clocking task"
  echo "---"
  previous_item
  echo "Open Emacs|terminal=false bash=$0 param1=open_emacs"
}

previous_item() {
  cmd='(s-join "\n" (--map (s-concat (car it) "%%%" (cdr it)) shou/previously-clocking))'
  eval echo -ne "$(emacs_exec "$cmd")" | \
        awk -F'%%%' \
            "{print \":fast_forward: Resume\", \$1 \"|terminal=false bash=$0 param1=resume param2=\"\$2}"
  echo "---"
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
    emacs_exec "(shou/mark-clocking-task-as-todo-and-clock-out)"
    ;;

  simply_clock_out)
    emacs_exec "(shou/temporarily-clock-out)"
    ;;

  done_and_clock_out)
    emacs_exec "(shou/mark-clocking-task-as-done)"
    ;;

  resume)
    emacs_exec "(shou/resume-previous-clock \"$2\")"
    ;;

  open_emacs)
    open -a "Emacs.app"
    ;;

  *)
    bitbar_show_menu
esac
