;;; super-save.el --- Auto-save buffers, based on your activity. -*- lexical-binding: t -*-

;; Copyright © 2015 Bozhidar Batsov <bozhidar@batsov.com>

;; Author: Bozhidar Batsov <bozhidar@batsov.com>
;; URL: https://github.com/bbatsov/super-save
;; Keywords: convenience
;; Version: 0.1.0

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

(defun super-save-command ()
  "Save the current buffer if needed."
  (when (and buffer-file-name
             (buffer-modified-p (current-buffer))
             (file-writable-p buffer-file-name))
    (save-buffer)))

(defmacro super-save-advise-commands (advice-name commands class &rest body)
  "Apply advice named ADVICE-NAME to multiple COMMANDS.

The body of the advice is in BODY."
  `(progn
     ,@(mapcar (lambda (command)
                 `(defadvice ,command (,class ,(intern (concat (symbol-name command) "-" advice-name)) activate)
                    ,@body))
               commands)))

(defun super-save-initialize ()
  (progn
    ;; advise all window switching functions
    (super-save-advise-commands
     "super-save"
     (switch-to-buffer other-window windmove-up windmove-down windmove-left windmove-right)
     before
     (super-save-command))

    (add-hook 'mouse-leave-buffer-hook #'super-save-command)

    (when (version<= "24.4" emacs-version)
      (add-hook 'focus-out-hook #'super-save-command))))

(provide 'super-save)
;;; super-save.el ends here
