;;; cmd-to-echo.el --- Show the output of long-running commands in the echo area -*- lexical-binding: t -*-

;; Copyright © 2016 Tijs Mallaerts
;;
;; Author: Tijs Mallaerts <tijs.mallaerts@gmail.com>

;; Package-Requires: ((emacs "24.4") (s "1.11.0"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Show the output long-running commands (f.ex. javascript bundlers)
;; in the echo area.

;;; Code:

(require 'comint)
(require 's)
(require 'ansi-color)

(defun cmd-to-echo--advice-put-text-property (orig-func start end property value object)
  "Make `put-text-property' put the face value instead of the font-lock-face.
ORIG-FUNC is the `put-text-property' function, START END PROPERTY
VALUE and OBJECT have the same meaning as in `put-text-property'."
  (funcall orig-func start end 'face value object))

(defun cmd-to-echo--ansi-color-apply (string)
  "Apply ansi colors to the STRING.
The regular `ansi-color-apply' cannot be used since it uses a font-lock-face,
and the echo area does not display that correctly."
  (advice-add 'put-text-property :around 'cmd-to-echo--advice-put-text-property)
  (let ((ansi-string (ansi-color-apply string)))
    (advice-remove 'put-text-property 'cmd-to-echo--advice-put-text-property)
    ansi-string))

(defun cmd-to-echo--proc-filter (proc str)
  "The process filter of the cmd-to-echo PROC.
The STR will be shown in the echo area."
  (message "%s" (s-trim (cmd-to-echo--ansi-color-apply str))))

;;;###autoload
(defun cmd-to-echo (command options)
  "Start the COMMAND with the given OPTIONS.
The output of the command will be shown in the echo area."
  (interactive
   (list (completing-read "Command to run: "
                          (split-string (shell-command-to-string "compgen -c")
                                        "\n"))
         (read-string "Options: ")))
  (apply 'make-comint (concat command options)
         command nil (split-string options " "))
  (let ((proc (get-process (concat command options))))
    (set-process-filter proc 'cmd-to-echo--proc-filter)))

(provide 'cmd-to-echo)

;;; cmd-to-echo.el ends here
