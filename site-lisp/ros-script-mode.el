;;; ros-script-mode.el --- Major mode for MikroTik RouterOS scripts (.rsc)  -*- lexical-binding: t; -*-



(defvar ros-script-keywords
'("if" "do" "else" "foreach" "while" "for" "in" "global" "local" "return" "on-error"))


(defvar ros-script-actions
'("add" "remove" "set" "get" "print" "find" "enable" "disable" "export" "import" "run" "execute" "monitor"))


(defvar ros-script-builtins
'("true" "false" "nil"))


(defvar ros-script-operators
'("and" "or" "not"))


(defvar ros-script-symbols
'("=" "!=" ">" "<" ">=" "<=" "+" "*" "/" "%" "&" "|" "~" "&&" "||" "!" "."))


(defun ros-script--match-variable (limit)
"Match RouterOS variable usage up to LIMIT."
(when (re-search-forward "\\$[A-Za-z0-9_-]+" limit t)
(set-match-data (match-data))
t))


(defvar ros-script-font-lock-defaults
`(
;; Comments
("#.*$" . font-lock-comment-face)
;; Strings
("\"\\(\\\\.\\|[^\"]\\)*\"" . font-lock-string-face)
;; Keywords
(,(concat "\\b" (regexp-opt ros-script-keywords t) "\\b") . font-lock-keyword-face)
;; Actions (first verb)
(,(concat "\\b" (regexp-opt ros-script-actions t) "\\b") . font-lock-function-name-face)
;; Builtins (constants)
(,(concat "\\b" (regexp-opt ros-script-builtins t) "\\b") . font-lock-constant-face)
;; Operators (word-like)
(,(concat "\\b" (regexp-opt ros-script-operators t) "\\b") . font-lock-builtin-face)
;; Symbols (non-word operators)
(,(regexp-opt ros-script-symbols) . font-lock-negation-char-face)
;; Variables
(ros-script--match-variable . font-lock-variable-name-face)
;; Parameter names before '=' (allowing hyphens)
("\\([A-Za-z0-9_-]+\\)\\s-*=" 1 font-lock-variable-name-face)
))


;;;###autoload
(define-derived-mode ros-script-mode prog-mode "ROS-Script"
"Major mode for editing MikroTik RouterOS scripts."
:syntax-table nil
(setq font-lock-defaults '(ros-script-font-lock-defaults))
(setq comment-start "#")
(setq comment-end "")
;; Treat hyphen as part of words, so aaa-bbb is one word, not split
(modify-syntax-entry ?- "w")
;; Bracket and delimiter handling
(modify-syntax-entry ?{ "(}")
(modify-syntax-entry ?} "){")
(modify-syntax-entry ?[ "([")
(modify-syntax-entry ?] "(]")
(modify-syntax-entry ?( "(")
(modify-syntax-entry ?) ")")
(modify-syntax-entry ?\" "\""))


;;;###autoload
(add-to-list 'auto-mode-alist '("\\.rsc\\'" . ros-script-mode))


(provide 'ros-script-mode)
