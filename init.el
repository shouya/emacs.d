;; startup time hacks

;; ----------- disable gc on startup -----------
(setq gc-cons-threshold most-positive-fixnum) ; 2^61 bytes
;; reset it after load
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 1024 1024 20))))

;; ----------- empty file handler alist --------
(defvar cfg--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda () (setq file-name-handler-alist cfg--file-name-handler-alist)))
(add-hook 'emacs-startup-hook
          (lambda () (message "Emacs ready in %.2f seconds with %d garbage collections."
                         (float-time (time-subtract after-init-time before-init-time))
                         gcs-done)))

;; ----------- load custom config --------------
(setq vc-follow-symlinks t)
(when (file-newer-than-file-p "~/.emacs.d/preferences.org"
                              "~/.emacs.d/preferences.el")
  (delete-file "~/.emacs.d/preferences.el"))
(org-babel-load-file "~/.emacs.d/preferences.org")
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
