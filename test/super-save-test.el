;;; super-save-test.el --- Tests for super-save -*- lexical-binding: t -*-

;;; Commentary:
;;
;; Buttercup test suite for super-save.
;;

;;; Code:

(require 'buttercup)
(require 'super-save)

;;; Helpers

(defmacro super-save-test-with-temp-file (&rest body)
  "Create a temp file, visit it, run BODY, then clean up."
  (declare (indent 0) (debug body))
  `(let ((temp-file (make-temp-file "super-save-test")))
     (unwind-protect
         (progn
           (find-file temp-file)
           ,@body)
       (when (get-file-buffer temp-file)
         (with-current-buffer (get-file-buffer temp-file)
           (set-buffer-modified-p nil)
           (kill-buffer)))
       (when (file-exists-p temp-file)
         (delete-file temp-file)))))

;;; Mode activation

(describe "super-save-mode"
  (after-each
    (super-save-mode -1))

  (it "can be enabled and disabled"
    (super-save-mode +1)
    (expect super-save-mode :to-be-truthy)
    (super-save-mode -1)
    (expect super-save-mode :not :to-be-truthy))

  (it "advises trigger commands when enabled"
    (super-save-mode +1)
    (expect (advice-member-p #'super-save-command-advice 'switch-to-buffer)
            :to-be-truthy))

  (it "removes advice from trigger commands when disabled"
    (super-save-mode +1)
    (super-save-mode -1)
    (expect (advice-member-p #'super-save-command-advice 'switch-to-buffer)
            :not :to-be-truthy))

  (it "registers window-change hooks when super-save-when-buffer-switched is t"
    (let ((super-save-when-buffer-switched t))
      (super-save-mode +1)
      (expect (memq #'super-save-window-change-handler
                    window-buffer-change-functions)
              :to-be-truthy)
      (expect (memq #'super-save-window-change-handler
                    window-selection-change-functions)
              :to-be-truthy)))

  (it "does not register window-change hooks when super-save-when-buffer-switched is nil"
    (let ((super-save-when-buffer-switched nil))
      (super-save-mode +1)
      (expect (memq #'super-save-window-change-handler
                    window-buffer-change-functions)
              :not :to-be-truthy)
      (expect (memq #'super-save-window-change-handler
                    window-selection-change-functions)
              :not :to-be-truthy)))

  (it "cleans up window-change hooks when disabled"
    (let ((super-save-when-buffer-switched t))
      (super-save-mode +1))
    (super-save-mode -1)
    (expect (memq #'super-save-window-change-handler
                  window-buffer-change-functions)
            :not :to-be-truthy)
    (expect (memq #'super-save-window-change-handler
                  window-selection-change-functions)
            :not :to-be-truthy)))

;;; Predicates

(describe "super-save-p"
  (it "returns t for a modified file-visiting buffer"
    (super-save-test-with-temp-file
      (insert "modified")
      (expect (super-save-p) :to-be-truthy)))

  (it "returns nil for a non-file-visiting buffer"
    (with-temp-buffer
      (expect (super-save-p) :not :to-be-truthy)))

  (it "returns nil for an unmodified buffer"
    (super-save-test-with-temp-file
      (expect (super-save-p) :not :to-be-truthy)))

  (it "returns nil when buffer-file-name matches super-save-exclude"
    (super-save-test-with-temp-file
      (insert "modified")
      (let ((super-save-exclude (list (regexp-quote (file-name-nondirectory buffer-file-name)))))
        (expect (super-save-p) :not :to-be-truthy))))

  (it "returns nil when buffer exceeds super-save-max-buffer-size"
    (super-save-test-with-temp-file
      (insert "modified")
      (let ((super-save-max-buffer-size 1))
        (expect (super-save-p) :not :to-be-truthy))))

  (it "returns t when super-save-max-buffer-size is nil"
    (super-save-test-with-temp-file
      (insert "modified")
      (let ((super-save-max-buffer-size nil))
        (expect (super-save-p) :to-be-truthy))))

  (it "returns nil when file has been modified externally"
    (super-save-test-with-temp-file
      (insert "modified")
      ;; Simulate external modification by changing the file's modtime
      (let ((temp-file buffer-file-name))
        (write-region "external change" nil temp-file nil 'silent)
        (expect (super-save-p) :not :to-be-truthy))))

  (it "returns nil when parent directory no longer exists"
    (let* ((temp-dir (make-temp-file "super-save-test-dir" t))
           (temp-file (expand-file-name "test.txt" temp-dir)))
      (unwind-protect
          (progn
            (write-region "content" nil temp-file)
            (find-file temp-file)
            (insert "modified")
            (delete-directory temp-dir t)
            (expect (super-save-p) :not :to-be-truthy))
        (when (get-file-buffer temp-file)
          (with-current-buffer (get-file-buffer temp-file)
            (set-buffer-modified-p nil)
            (kill-buffer)))
        (when (file-exists-p temp-dir)
          (delete-directory temp-dir t))))))

(describe "super-save-p error handling"
  (it "handles broken predicates gracefully"
    (super-save-test-with-temp-file
      (insert "modified")
      (let ((super-save-predicates
             (list (lambda () (error "Broken predicate")))))
        (expect (super-save-p) :not :to-be-truthy))))

  (it "logs a message when a predicate errors"
    (super-save-test-with-temp-file
      (insert "modified")
      (let ((super-save-predicates
             (list (lambda () (error "Broken predicate")))))
        (spy-on 'message)
        (super-save-p)
        (expect 'message :to-have-been-called)))))

;;; super-save-include-p

(describe "super-save-include-p"
  (it "returns t when no excludes are set"
    (let ((super-save-exclude nil))
      (expect (super-save-include-p "/some/file.el") :to-be-truthy)))

  (it "returns nil when filename matches an exclude pattern"
    (let ((super-save-exclude '("\\.gpg$")))
      (expect (super-save-include-p "/some/file.gpg") :not :to-be-truthy)))

  (it "returns t when filename does not match any exclude pattern"
    (let ((super-save-exclude '("\\.gpg$")))
      (expect (super-save-include-p "/some/file.el") :to-be-truthy))))

;;; Saving

(describe "super-save-command"
  (it "saves a modified file-visiting buffer"
    (super-save-test-with-temp-file
      (insert "new content")
      (super-save-command)
      (expect (buffer-modified-p) :not :to-be-truthy)))

  (it "does not save an unmodified buffer"
    (super-save-test-with-temp-file
      (spy-on 'basic-save-buffer)
      (super-save-command)
      (expect 'basic-save-buffer :not :to-have-been-called)))

  (it "saves silently when super-save-silent is t"
    (super-save-test-with-temp-file
      (insert "new content")
      (let ((super-save-silent t))
        (spy-on 'basic-save-buffer :and-call-through)
        (super-save-command)
        (expect 'basic-save-buffer :to-have-been-called)
        (expect (buffer-modified-p) :not :to-be-truthy)))))

(describe "super-save-command with super-save-all-buffers"
  (it "saves all modified buffers when super-save-all-buffers is t"
    (let ((temp-file-1 (make-temp-file "super-save-test-1"))
          (temp-file-2 (make-temp-file "super-save-test-2"))
          (super-save-all-buffers t))
      (unwind-protect
          (progn
            (find-file temp-file-1)
            (insert "content 1")
            (find-file temp-file-2)
            (insert "content 2")
            (super-save-command)
            (expect (buffer-modified-p) :not :to-be-truthy)
            (with-current-buffer (get-file-buffer temp-file-1)
              (expect (buffer-modified-p) :not :to-be-truthy)))
        (dolist (f (list temp-file-1 temp-file-2))
          (when (get-file-buffer f)
            (with-current-buffer (get-file-buffer f)
              (set-buffer-modified-p nil)
              (kill-buffer)))
          (when (file-exists-p f)
            (delete-file f)))))))

;;; Trailing whitespace

(describe "super-save-delete-trailing-whitespace-maybe"
  (it "does nothing when super-save-delete-trailing-whitespace is nil"
    (super-save-test-with-temp-file
      (insert "hello   ")
      (let ((super-save-delete-trailing-whitespace nil))
        (super-save-delete-trailing-whitespace-maybe)
        (expect (buffer-string) :to-match "hello   "))))

  (it "deletes trailing whitespace when super-save-delete-trailing-whitespace is t"
    (super-save-test-with-temp-file
      (insert "hello   \n")
      (goto-char (point-min))
      (let ((super-save-delete-trailing-whitespace t))
        (super-save-delete-trailing-whitespace-maybe)
        (expect (buffer-string) :to-equal "hello\n"))))

  (it "preserves current line whitespace with except-current-line"
    (super-save-test-with-temp-file
      (insert "line1   \nline2   \nline3   ")
      (goto-char (point-min))
      (forward-line 1)
      (end-of-line)
      (let ((super-save-delete-trailing-whitespace 'except-current-line))
        (super-save-delete-trailing-whitespace-maybe)
        (expect (buffer-string) :to-equal "line1\nline2   \nline3")))))

;;; Special buffer detection

(describe "super-save-org-src-buffer-p"
  (it "returns nil in a regular buffer"
    (with-temp-buffer
      (expect (super-save-org-src-buffer-p) :not :to-be-truthy))))

(describe "super-save-edit-indirect-buffer-p"
  (it "returns nil in a regular buffer"
    (with-temp-buffer
      (expect (super-save-edit-indirect-buffer-p) :not :to-be-truthy))))

;;; super-save-test.el ends here
