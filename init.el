;; startup time hacks

;; ----------- disable gc on startup -----------
(setq gc-cons-threshold most-positive-fixnum) ; 2^61 bytes
(setq gc-cons-percentage 0.4)
;; reset it after load
(add-hook 'after-init-hook
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
                         (float-time (time-subtract after-init-time before-init-time))
                         gcs-done)))

;; ----- load straight.el first ----------
(defvar bootstrap-version)
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
  (load bootstrap-file nil 'nomessage)
  (require 'straight-x))

;; 9.4.4 without the following line, otherwise 9.4.6
(straight-use-package 'org)

;; ----------- load custom config --------------
(setq vc-follow-symlinks t)
(when (file-newer-than-file-p "~/.emacs.d/preferences.org"
                              "~/.emacs.d/preferences.el")
  (delete-file "~/.emacs.d/preferences.el"))
(load-file (expand-file-name "secrets.el" "~/.emacs.d"))
(org-babel-load-file "~/.emacs.d/preferences.org")
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
