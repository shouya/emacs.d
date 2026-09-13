;;; majutsu-log-expand.el --- Expand elided revisions in Majutsu log buffers -*- lexical-binding: t; -*-

;;; Commentary:

;; `+' and `-' grow and shrink the set of revisions a Majutsu log buffer
;; shows, at the elision markers jj prints.  The expansion is kept in a
;; buffer-local layer and unioned into the revset only when the `jj log'
;; command is assembled, so the `-r' the user typed is never rewritten.
;;
;; Prototype for an upstream majutsu feature.

;;; Code:

(require 'majutsu-log)
(require 'transient)

(defcustom majutsu-log-expand-step 5
  "Generations added to an elided segment by one `majutsu-log-expand'."
  :type 'natnum
  :group 'majutsu)

(defconst majutsu-log-expand--marker ?~
  "The graph node jj draws where it left revisions out.
It marks both a hole between two shown revisions, which jj labels
\"(elided revisions)\", and a branch whose remaining ancestors are all
unshown, whose row carries no text at all.  The node is the only signal
common to the two, and majutsu keeps the graph in `line-prefix'.")

(defconst majutsu-log-expand--graph-lines '(?\s ?| ?- ?\\ ?/)
  "Non-node characters jj's ascii graph styles draw.
The other styles draw lines from the Box Drawing block instead.")

(defvar-local majutsu-log-expand--depths nil
  "Alist of (CHANGE-ID . DEPTH) for segments expanded in this buffer.
DEPTH is a generation count, or `all' for every ancestor.")

(defvar-local majutsu-log-expand--anchor 'unset
  "The `--revision=' value the recorded expansions belong to.
Expansions are dropped once the buffer selects a different revset.")

(defvar-local majutsu-log-expand--default-revset nil
  "Cached `revsets.log', used as base when the buffer has no `-r'.")

;;; Revset assembly

(defun majutsu-log-expand--revision-arg-p (arg)
  (and (stringp arg)
       (or (string-prefix-p "--revision=" arg)
           (string-prefix-p "--revisions=" arg))))

(defun majutsu-log-expand--revision-value (args)
  "Return the revset selected by ARGS, or nil when it selects the default."
  (or (transient-arg-value "--revision=" args)
      (transient-arg-value "--revisions=" args)))

(defun majutsu-log-expand--base-revset (args)
  "Return the revset ARGS select, expansions aside."
  (or (majutsu-log-expand--revision-value args)
      (setq majutsu-log-expand--default-revset
            (or majutsu-log-expand--default-revset
                (majutsu-get "revsets.log")))
      "builtin_log()"))

(defun majutsu-log-expand--term (id depth)
  (if (eq depth 'all)
      (format "ancestors(%s-)" id)
    (format "ancestors(%s-, %d)" id depth)))

(defun majutsu-log-expand--revset (args)
  "Return the base revset of ARGS unioned with this buffer's expansions."
  (string-join
   (cons (format "(%s)" (majutsu-log-expand--base-revset args))
         (mapcar (lambda (cell)
                   (majutsu-log-expand--term (car cell) (cdr cell)))
                 majutsu-log-expand--depths))
   " | "))

(defun majutsu-log-expand--set-revision (command revset)
  "Return COMMAND with its revision argument set to REVSET."
  (let ((arg (concat "--revision=" revset))
        (placed nil)
        (out nil))
    (dolist (item command)
      (cond
       ((majutsu-log-expand--revision-arg-p item)
        (unless placed
          (push arg out)
          (setq placed t)))
       (t
        (push item out)
        (when (and (not placed) (equal item "log"))
          (push arg out)
          (setq placed t)))))
    (nreverse out)))

(defun majutsu-log-expand--stale-p (command)
  "Return non-nil when recorded expansions belong to another revset."
  (not (equal (majutsu-log-expand--revision-value command)
              majutsu-log-expand--anchor)))

(defun majutsu-log-expand--filter-build-args (command)
  "Union this buffer's expansions into the `jj log' COMMAND."
  (when (and majutsu-log-expand--depths
             (derived-mode-p 'majutsu-log-mode)
             (majutsu-log-expand--stale-p command))
    (setq majutsu-log-expand--depths nil))
  (if (and majutsu-log-expand--depths (derived-mode-p 'majutsu-log-mode))
      (majutsu-log-expand--set-revision
       command (majutsu-log-expand--revset command))
    command))

(advice-add 'majutsu-log--build-args :filter-return
            #'majutsu-log-expand--filter-build-args)

;;; Elided segments

(defun majutsu-log-expand--section-id (section)
  (and section
       (eq (oref section type) 'jj-commit)
       (stringp (oref section value))
       (substring-no-properties (oref section value))))

(defun majutsu-log-expand--graph-node (prefix)
  "Return the node glyph drawn in graph PREFIX, or nil when it draws none.
A node can sit left of columns that belong to other branches, as in
\"~ |  (elided revisions)\", so the node is the first glyph that is not a
graph line rather than the last glyph of PREFIX."
  (and (stringp prefix)
       (seq-find (lambda (ch)
                   (not (or (memq ch majutsu-log-expand--graph-lines)
                            (<= #x2500 ch #x257F))))
                 prefix)))

(defun majutsu-log-expand--marker-row-p ()
  "Return non-nil when the row at point draws the elision node."
  (eq (majutsu-log-expand--graph-node
       (get-text-property (line-beginning-position) 'line-prefix))
      majutsu-log-expand--marker))

(defun majutsu-log-expand--marked-p (section)
  "Return non-nil when SECTION spans an elision marker row."
  (save-excursion
    (goto-char (oref section start))
    (let ((end (oref section end))
          (found nil))
      (while (and (not found) (not (eobp)) (< (point) end))
        (setq found (majutsu-log-expand--marker-row-p))
        (forward-line 1))
      found)))

(defun majutsu-log-expand--owner-at-point ()
  "Return the change id of the elided segment at point, if any.
A commit already carrying an expansion counts as its own segment, so
repeated commands keep walking the same one as its marker moves down."
  (when-let* ((section (magit-current-section))
              (id (majutsu-log-expand--section-id section)))
    (and (or (majutsu-log-expand--marked-p section)
             (assoc id majutsu-log-expand--depths))
         id)))

(defun majutsu-log-expand--all-owners ()
  "Return the change ids of every elided segment in the buffer."
  (let (ids)
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (when (majutsu-log-expand--marker-row-p)
          (when-let* ((id (majutsu-log-expand--section-id (magit-current-section))))
            (unless (member id ids)
              (push id ids))))
        (forward-line 1)))
    (nreverse ids)))

;;; Depth bookkeeping

(defun majutsu-log-expand--depth (id)
  (cdr (assoc id majutsu-log-expand--depths)))

(defun majutsu-log-expand--set-depth (id depth)
  "Record DEPTH for ID, or forget ID when DEPTH is nil."
  (if depth
      (setf (alist-get id majutsu-log-expand--depths nil nil #'equal) depth)
    (setq majutsu-log-expand--depths
          (assoc-delete-all id majutsu-log-expand--depths))))

(defun majutsu-log-expand--grow (depth arg)
  "Return DEPTH grown as prefix ARG asks."
  (cond
   ((consp arg) 'all)
   ((eq depth 'all) 'all)
   ((natnump arg) (+ (or depth 0) arg))
   (t (+ (or depth 0) majutsu-log-expand-step))))

(defun majutsu-log-expand--shrink (depth arg)
  "Return DEPTH shrunk as prefix ARG asks, or nil to forget it."
  (cond
   ((consp arg) nil)
   ((eq depth 'all) majutsu-log-expand-step)
   ((null depth) nil)
   (t (let ((next (- depth (if (natnump arg) arg majutsu-log-expand-step))))
        (and (> next 0) next)))))

;;; Commands

(defun majutsu-log-expand--visible-count ()
  (if (hash-table-p majutsu-log--entry-by-id)
      (hash-table-count majutsu-log--entry-by-id)
    0))

(defun majutsu-log-expand--limit ()
  (transient-arg-value "--limit=" majutsu-buffer-log-args))

(defun majutsu-log-expand--apply (ids focus &optional undo-futile previous)
  "Re-render the buffer, keep point on FOCUS and report what IDS did.
With UNDO-FUTILE, restore the PREVIOUS depth alist when no revision
appears, so depths stop growing once jj has nothing left to show."
  (let ((before (majutsu-log-expand--visible-count)))
    (setq majutsu-log-expand--anchor
          (majutsu-log-expand--revision-value majutsu-buffer-log-args))
    (majutsu-refresh-buffer)
    (when focus
      (majutsu--goto-log-entry focus))
    (let ((delta (- (majutsu-log-expand--visible-count) before)))
      (when (and undo-futile (<= delta 0))
        (setq majutsu-log-expand--depths previous))
      (cond
       ((/= delta 0)
        (message "%s%d revision%s" (if (> delta 0) "+" "") delta
                 (if (= 1 (abs delta)) "" "s")))
       ((majutsu-log-expand--limit)
        (message "Nothing new; --limit=%s is in effect"
                 (majutsu-log-expand--limit)))
       (t
        (message "Nothing elided below %s"
                 (mapconcat (lambda (id) (substring id 0 (min 8 (length id))))
                            ids ", ")))))))

;;;###autoload
(defun majutsu-log-expand (&optional arg)
  "Show revisions elided below the commit at point.
Without a segment at point, expand every elided segment in the buffer.
A numeric prefix ARG expands by that many generations instead of
`majutsu-log-expand-step'; a plain prefix argument expands completely."
  (interactive "P")
  (majutsu--assert-mode 'majutsu-log-mode)
  (let* ((owner (majutsu-log-expand--owner-at-point))
         (ids (or (and owner (list owner))
                  (majutsu-log-expand--all-owners)))
         (previous (copy-alist majutsu-log-expand--depths)))
    (unless ids
      (user-error "Nothing is elided in this log buffer"))
    (dolist (id ids)
      (majutsu-log-expand--set-depth
       id (majutsu-log-expand--grow (majutsu-log-expand--depth id) arg)))
    (majutsu-log-expand--apply ids (or owner (majutsu-revision-at-point))
                               t previous)))

;;;###autoload
(defun majutsu-log-expand-less (&optional arg)
  "Undo part of the expansion below the commit at point.
Without an expanded segment at point, shrink every expansion in the
buffer.  A numeric prefix ARG shrinks by that many generations; a plain
prefix argument drops the expansion entirely."
  (interactive "P")
  (majutsu--assert-mode 'majutsu-log-mode)
  (let* ((owner (majutsu-log-expand--owner-at-point))
         (ids (or (and owner (assoc owner majutsu-log-expand--depths) (list owner))
                  (mapcar #'car majutsu-log-expand--depths))))
    (unless ids
      (user-error "No expansion to undo in this log buffer"))
    (dolist (id ids)
      (majutsu-log-expand--set-depth
       id (majutsu-log-expand--shrink (majutsu-log-expand--depth id) arg)))
    (majutsu-log-expand--apply ids (or owner (majutsu-revision-at-point)))))

(keymap-set majutsu-log-mode-map "+" #'majutsu-log-expand)
(keymap-set majutsu-log-mode-map "-" #'majutsu-log-expand-less)

;;; _
(provide 'majutsu-log-expand)
;;; majutsu-log-expand.el ends here
