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
(defgroup super-save nil
  "Smart-saving of buffers."
  :group 'tools
  :group 'convenience)

(defcustom super-save-triggers
  '(switch-to-buffer other-window windmove-up windmove-down windmove-left windmove-right)
  "A list of commands which would trigger `super-save-command'."
  :group 'super-save
  :type '(repeat symbol))

(defun super-save-command ()
  "Save the current buffer if needed."
  (when (and buffer-file-name
             (buffer-modified-p (current-buffer))
             (file-writable-p buffer-file-name))
    (save-buffer)))

(defmacro super-save-advise-trigger-commands ()
  "Apply super-save advice to the commands listed in `super-save-triggers'."
  `(progn
     ,@(mapcar (lambda (command)
                 `(defadvice ,command (before ,(intern (concat (symbol-name command) "-super-save")) activate)
                    (super-save-command)))
               super-save-triggers)))

(defun super-save-initialize ()
  (progn
    ;; advise all window switching functions
    (super-save-advise-trigger-commands)

    (add-hook 'mouse-leave-buffer-hook #'super-save-command)

    (when (version<= "24.4" emacs-version)
      (add-hook 'focus-out-hook #'super-save-command))))

(provide 'super-save)
;;; super-save.el ends here
