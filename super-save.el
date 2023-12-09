;;; super-save.el --- Auto-save buffers, based on your activity. -*- lexical-binding: t -*-

;; Copyright © 2015-2023 Bozhidar Batsov <bozhidar@batsov.com>

;; Author: Bozhidar Batsov <bozhidar@batsov.com>
;; URL: https://github.com/bbatsov/super-save
;; Keywords: convenience
;; Version: 0.4.0
;; Package-Requires: ((emacs "25.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; super-save saves buffers when they lose focus.
;;
;;; Code:

(require 'seq)

(defgroup super-save nil
  "Smart-saving of buffers."
  :group 'tools
  :group 'convenience)

(defvar super-save-mode-map
  (make-sparse-keymap)
  "super-save mode's keymap.")

(defcustom super-save-triggers
  '(switch-to-buffer other-window windmove-up windmove-down windmove-left windmove-right next-buffer previous-buffer)
  "A list of commands which would trigger `super-save-command'."
  :group 'super-save
  :type '(repeat symbol)
  :package-version '(super-save . "0.1.0"))

(defcustom super-save-hook-triggers
  '(mouse-leave-buffer-hook focus-out-hook)
  "A list of hooks which would trigger `super-save-command'."
  :group 'super-save
  :type '(repeat symbol)
  :package-version '(super-save . "0.3.0"))

(defcustom super-save-auto-save-when-idle nil
  "Save automatically when Emacs is idle."
  :group 'super-save
  :type 'boolean
  :package-version '(super-save . "0.2.0"))

(defcustom super-save-all-buffers nil
  "Auto-save all buffers, not just the current one.

Setting this to t can be interesting when you make indirect buffer edits, like
when editing `grep's results with `occur-mode' and 'occur-edit-mode', or when
running a project-wide search and replace with `project-query-replace-regexp'
and so on.  In these cases, we can indirectly edit several buffers without
actually visiting or switching to these buffers.  Hence, this option allow to
automatically save these buffers, even when they aren't visible in any window."
  :group 'super-save
  :type 'boolean
  :package-version '(super-save . "0.4.0"))

(defcustom super-save-idle-duration 5
  "Delay in seconds for which Emacs has to be idle before auto-saving.
See `super-save-auto-save-when-idle'."
  :group 'super-save
  :type 'integer
  :package-version '(super-save . "0.2.0"))

(defcustom super-save-remote-files t
  "Save remote files when t, ignore them otherwise."
  :group 'super-save
  :type 'boolean
  :package-version '(super-save . "0.3.0"))

(defcustom super-save-silent nil
  "Save silently, don't display any message."
  :group 'super-save
  :type 'boolean
  :package-version '(super-save . "0.4.0"))

(defcustom super-save-delete-trailing-whitespace nil
  "Controls whether to delete the trailing whitespace before saving.
Set to 'except-current-line if you want to avoid the current line."
  :group 'super-save
  :type '(choice (boolean :tag "Enable/disable deleting trailing whitespace for the whole buffer.")
          (symbol :tag "Delete trailing whitespace except the current line." except-current-line))
  :package-version '(super-save . "0.4.0"))

(defcustom super-save-exclude nil
  "A list of regexps for `buffer-file-name' excluded from super-save.
When a `buffer-file-name' matches any of the regexps it is ignored."
  :group 'super-save
  :type '(repeat (choice regexp))
  :package-version '(super-save . "0.4.0"))

(defcustom super-save-max-buffer-size nil
  "Maximal size of buffer (in characters), for which super-save work.
Exists mostly because saving constantly huge buffers can be slow in some cases.
Set to 0 or nil to disable."
  :group 'super-save
  :type 'integer
  :package-version '(super-save . "0.4.0"))

(defcustom super-save-predicates
  '((lambda () buffer-file-name)
    (lambda () (buffer-modified-p (current-buffer)))
    (lambda () (file-writable-p buffer-file-name))
    (lambda () (if (and super-save-max-buffer-size (> super-save-max-buffer-size 0))
                   (< (buffer-size) super-save-max-buffer-size)
                 t))
    (lambda ()
      (if (file-remote-p buffer-file-name) super-save-remote-files t))
    (lambda () (super-save-include-p buffer-file-name)))
  "Predicates, which return nil, when the buffer doesn't need to be saved.
Predicate functions don't take any arguments.  If a predicate doesn't know
whether this buffer needs to be super-saved or not, then it must return t."
  :group 'super-save
  :type 'integer
  :package-version '(super-save . "0.4.0"))

(defun super-save-include-p (filename)
  "Return non-nil if FILENAME doesn't match any of the `super-save-exclude'."
  (not (seq-some (lambda (regexp) (string-match-p regexp filename)) super-save-exclude)))

(defun super-save-p ()
  "Return t when current buffer should be saved, otherwise return nil.

This function relies on the variable `super-save-predicates'."
  (seq-every-p #'funcall super-save-predicates))

(defun super-save-delete-trailing-whitespace-maybe ()
  "Delete trailing whitespace, optionally avoiding the current line.

See `super-save-delete-trailing-whitespace'."
  (cond
   ((eq super-save-delete-trailing-whitespace 'except-current-line)
    (let ((start (line-beginning-position))
          (current (point)))
      (save-excursion
        (when (< (point-min) start)
          (save-restriction
            (narrow-to-region (point-min) (1- start))
            (delete-trailing-whitespace)))
        (when (> (point-max) current)
          (save-restriction
            (narrow-to-region current (point-max))
            (delete-trailing-whitespace))))))
   (super-save-delete-trailing-whitespace
    (delete-trailing-whitespace))))

(defun super-save-buffer (buffer)
  "Save BUFFER if needed, super-save style."
  (with-current-buffer buffer
    (save-excursion
      (when (super-save-p)
        (super-save-delete-trailing-whitespace-maybe)
        (if super-save-silent
            (with-temp-message ""
              (let ((inhibit-message t)
                    (inhibit-redisplay t)
                    (message-log-max nil))
                (basic-save-buffer)))
          (basic-save-buffer))))))

(defun super-save-command ()
  "Save the relevant buffers if needed.

When `super-save-all-buffers' is non-nil, save all modified buffers, else, save
only the current buffer."
  (mapc #'super-save-buffer (if super-save-all-buffers (buffer-list) (list (current-buffer)))))

(defvar super-save-idle-timer)

(defun super-save-command-advice (&rest _args)
  "A simple wrapper around `super-save-command' that's advice-friendly."
  (super-save-command))

(defun super-save-advise-trigger-commands ()
  "Apply super-save advice to the commands listed in `super-save-triggers'."
  (mapc
   (lambda (command)
     (advice-add command :before #'super-save-command-advice))
   super-save-triggers))

(defun super-save-remove-advice-from-trigger-commands ()
  "Remove super-save advice from to the commands listed in `super-save-triggers'."
  (mapc
   (lambda (command)
     (advice-remove command #'super-save-command-advice))
   super-save-triggers))

(defun super-save-initialize-idle-timer ()
  "Initialize super-save idle timer if `super-save-auto-save-when-idle' is true."
  (setq super-save-idle-timer
        (when super-save-auto-save-when-idle
          (run-with-idle-timer super-save-idle-duration t #'super-save-command))))

(defun super-save-stop-idle-timer ()
  "Stop super-save idle timer if `super-save-idle-timer' is set."
  (when super-save-idle-timer (cancel-timer super-save-idle-timer)))

(defun super-save-initialize ()
  "Setup super-save's advices and hooks."
  (super-save-advise-trigger-commands)
  (super-save-initialize-idle-timer)
  (dolist (hook super-save-hook-triggers)
    (add-hook hook #'super-save-command)))

(defun super-save-stop ()
  "Cleanup super-save's advices and hooks."
  (super-save-remove-advice-from-trigger-commands)
  (super-save-stop-idle-timer)
  (dolist (hook super-save-hook-triggers)
    (remove-hook hook #'super-save-command)))

;;;###autoload
(define-minor-mode super-save-mode
  "A minor mode that saves your Emacs buffers when they lose focus."
  :lighter " super-save"
  :keymap super-save-mode-map
  :group 'super-save
  :global t
  (cond
   (super-save-mode (super-save-initialize))
   (t (super-save-stop))))

(provide 'super-save)
;;; super-save.el ends here
