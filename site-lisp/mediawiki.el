(defvar mediawiki-mode-font-lock-keywords
  (list
   ;; wiki link
   (list (rx (group "[[") (group (* (not (in "[]")))) (group "]]"))
         '(1 font-lock-builtin-face t t)
         '(2 font-lock-function-name-face t t)
         '(3 font-lock-builtin-face t t))
   ;; external link
   (list (rx (group "[")
             (group (* (not (in "[]"))))
             (+ " ")
             (group (* (not (in "[]"))))
             (group "]"))
         '(1 font-lock-builtin-face t t)
         '(2 font-lock-constant-face t t)
         '(3 font-lock-function-name-face t t)
         '(4 font-lock-builtin-face t t))
   ;; template
   (list (rx (group "{{") (group (* (not (in "{}")))) (group "}}"))
         '(1 font-lock-builtin-face t t)
         '(2 font-lock-keyword-face t t)
         '(3 font-lock-builtin-face t t))
   ))

(define-derived-mode mediawiki-mode text-mode "MediaWiki"
  "Major mode for editing MediaWiki"
  (setq-local font-lock-defaults '(mediawiki-mode-font-lock-keywords)))
