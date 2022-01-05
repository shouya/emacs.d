;; startup time hacks

;; ----------- disable gc on startup -----------
(setq gc-cons-threshold most-positive-fixnum) ; 2^61 bytes
(setq gc-cons-percentage 0.4)
;; reset it after load
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 60 1024 1024))))
;; force garbage collect when out of focus
(add-hook 'focus-out-hook 'garbage-collect)

;; ----------- empty file handler alist --------
(defvar cfg--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda () (setq file-name-handler-alist cfg--file-name-handler-alist)))
(add-hook 'emacs-startup-hook
          (lambda () (message "Emacs ready in %.2f seconds with %d garbage collections."
                         (float-time (time-subtract (current-time) before-init-time))
                         gcs-done)))

;; ----- load straight.el first ----------
(defvar bootstrap-version)

;; makes booting a lot faster by avoiding checking modifications made
;; in package source codes, which I rarely do.

(setq straight-check-for-modifications nil)
;; prevent the unnecessary package-initialize by package.el which is
;; very slow
(setq package-activated-list nil)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; must load org before calling org-babel. Otherwise it tries to use system org
(straight-use-package 'org)

;; ----------- load custom config --------------
(setq vc-follow-symlinks t)
(when (file-newer-than-file-p "~/.emacs.d/preferences.org"
                              "~/.emacs.d/preferences.el")
  (delete-file "~/.emacs.d/preferences.el"))
(load-file (expand-file-name "secrets.el" "~/.emacs.d"))

;; this avoid jit emacs from compiling the file using system org mode
(with-eval-after-load 'org
  (org-babel-load-file "~/.emacs.d/preferences.org")
  )
(require 'org)

;; ---------- config managed by emacs ----------
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
