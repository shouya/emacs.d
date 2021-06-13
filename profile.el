;;; Load this file instead of the init file to profiling startup

(profiler-start 'cpu)
(add-hook 'emacs-startup-hook
          (lambda () (profiler-report)))
(load (concat user-emacs-directory "init.el"))
