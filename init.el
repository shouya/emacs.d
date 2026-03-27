;; startup time hacks

;; ----------- disable gc on startup -----------
(setq gc-cons-threshold most-positive-fixnum) ; 2^61 bytes
(setq gc-cons-percentage 0.4)
;; reset it after load
(add-hook 'after-init-hook
          (lambda () (setq gc-cons-threshold (* 100 1024 1024))))
;; force garbage collect when out of focus
(add-hook 'focus-out-hook 'garbage-collect)

;; ----------- empty file handler alist --------
(defvar cfg--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
	    (setq file-name-handler-alist cfg--file-name-handler-alist)))
(add-hook 'emacs-startup-hook
          (lambda () (message "Emacs ready in %.2f seconds with %d garbage collections."
                              (float-time (time-subtract (current-time) before-init-time))
                              gcs-done)))

;; Inhibit resizing frame on font changes
;; Emacs resizing itself is pointless as I use tiling window manager
(setq frame-inhibit-implied-resize t)

;; ----------- initialize elpaca ---------------
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; -- enable use-package
(elpaca elpaca-use-package
  (elpaca-use-package-mode)
  ;; I would like to manually specify :ensure t for packages I want it to fetch
  (setq elpaca-use-package-by-default nil)
  (setq use-package-always-ensure nil)
  )
(elpaca-wait)

;; use package configuration
(setq use-package-always-defer t)
(setq use-package-compute-statistics t)

;; ----------- load custom config --------------
(setq vc-follow-symlinks t)
(when (file-newer-than-file-p "~/.emacs.d/preferences.org"
                              "~/.emacs.d/preferences.el")
  (delete-file "~/.emacs.d/preferences.el")
  (require 'org)
  (org-babel-tangle-file
   "~/.emacs.d/preferences.org"
   "~/.emacs.d/preferences.el"
   (rx string-start (or "emacs-lisp" "elisp") string-end)
  ))

(load-file (expand-file-name "secrets.el" "~/.emacs.d"))
(load-file (expand-file-name "preferences.el" "~/.emacs.d"))

;; ---------- config managed by emacs ----------
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
