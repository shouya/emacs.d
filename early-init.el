;;; early-init.el --- runs before package.el and the first frame -*- lexical-binding: t; -*-

;; elpaca manages packages, package.el must not activate anything.
(setq package-enable-at-startup nil)

;; init.el and preferences.org are symlinks into the nix store.
(setq vc-follow-symlinks t)

;; Inhibit resizing frame on font changes
;; Emacs resizing itself is pointless as I use tiling window manager
(setq frame-inhibit-implied-resize t)

;; Keep the UI elements out of the initial frame parameters, so they are
;; never built. Toggling the corresponding modes still works.
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(setq tool-bar-mode nil
      menu-bar-mode nil
      scroll-bar-mode nil)
