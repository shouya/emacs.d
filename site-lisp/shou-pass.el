(defvar shou/cached-pass-entries '())

;;;###autoload
(defun shou/get-pass-entry (entry)
  (if-let ((value (assoc entry shou/cached-pass-entries)))
      (cdr value)
    (let ((file-name-handler-alist
           '(("\\.gpg\\(~\\|\\.~[0-9]+~\\)?\\'" . epa-file-handler))))
      (let ((pass-entry (auth-source-pass-get 'secret entry)))
        (push (cons entry pass-entry) shou/cached-pass-entries)
        pass-entry))))

(provide 'shou-pass)
