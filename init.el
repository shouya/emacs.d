;; startup time hacks

;; ----------- disable gc on startup -----------
(setq gc-cons-threshold most-positive-fixnum) ; 2^61 bytes
;; reset it after load
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold 800000)))

;; ----------- empty file handler alist --------
(defvar cfg--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda () (setq file-name-handler-alist cfg--file-name-handler-alist)))
(add-hook 'emacs-startup-hook
          (lambda () (message "Emacs ready in %.2f seconds with %d garbage collections."
                         (float-time (time-subtract after-init-time before-init-time))
                         gcs-done)))


(org-babel-load-file "~/.emacs.d/preferences.org")
