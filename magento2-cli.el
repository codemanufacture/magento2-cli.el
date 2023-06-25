;;; magento2-cli.el --- Magento 2 command-line interface -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Codemanufacture SLRS development

;; Author: Piotr Kwiecinski <piotr.kwiecinski@codemanufacture.com>
;; Version: 0.0.1
;; Package-Requires: ((emacs "28.1"))
;; Homepage: https://github.com/codemanufacture/magento2-cli.el
;; Keywords: tools magento
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; `magento2-cli.el` is Magento 2 command-line interface for Emacs.
;;
;; ## Commands
;;
;; - M-x magento2-cli - Run composer sub command (with completing read)

;;; Code:
(require 'compile)
(require 'json)
(require 'seq)
(require 'consult nil t)

(eval-when-compile
  (declare-function
   consult--read "ext:consult"
   (candidates &rest options &key
               prompt predicate require-match history default
               keymap category initial narrow add-history annotate
               state preview-key sort lookup group inherit-input-method)))

;;; Variables
(defvar magento2-cli-executable-bin "bin/magento"
  "Path to `bin/magento' exec file.")

(defvar magento2-cli--async-use-compilation t)

(defvar magento2-cli--execute-interactive nil)

(defvar magento2-cli--quote-shell-argument t)

;;; Customize
(defgroup magento2-cli nil
  "Interface to Magento 2 command-line."
  :group 'external
  :group 'tools
  :tag "Magento 2 CLI"
  :prefix "magento2-cli")

(defcustom magento2-cli-use-ansi-color nil
  "Use ansi color code on `bin/magento' command execution."
  :type 'boolean)

(defcustom magento2-cli-interactive-commands
  '("admin:user:create"
    "varnish:vcl:generate")
  "List of interactive commands."
  :type '(repeat string))

(defun magento2-cli--find-magento-root (directory)
  "Return path which includes `composer.json' DIRECTORY."
  (locate-dominating-file directory "app/etc/config.php"))

(defun magento2-cli--parse-json-string (json)
  "Parse from JSON string."
  (with-temp-buffer
    (insert json)
    (goto-char (point-min))
    (if (eval-when-compile (and (fboundp 'json-serialize)
                                (fboundp 'json-parse-buffer)))
        (with-no-warnings
          (json-parse-buffer :object-type 'alist :array-type 'array))
      (let ((json-object-type 'alist) (json-array-type 'vector))
        (json-read-object)))))

(defun magento2-cli--async-command-execute (command &rest args)
  "Execute `bin/magento' command COMMAND by ARGS asynchonously."
  (let ((default-directory (or (magento2-cli--find-magento-root default-directory)
                               default-directory)))
    (if magento2-cli--async-use-compilation
        (compile (magento2-cli--make-command-string command args))
      (async-shell-command (magento2-cli--make-command-string command args) nil nil))))

(defun magento2-cli--command-execute (command &rest args)
  "Execute `bin/magento' command COMMAND by ARGS."
  (let ((default-directory (or (magento2-cli--find-magento-root default-directory)
                               default-directory)))
    (if magento2-cli--execute-interactive
        (compile (magento2-cli--make-command-string command args) t)
      (shell-command-to-string (magento2-cli--make-command-string command args)))))

(defun magento2-cli--make-command-string (command args)
  "Return command string by `COMMAND' and `ARGS'."
  (mapconcat
   (if magento2-cli--quote-shell-argument 'shell-quote-argument 'identity)
   (append (list magento2-cli-executable-bin)
           (append
            (list command)
            (if magento2-cli--execute-interactive nil '("--no-interaction"))
            args))
   " "))

(defun magento2-cli--list-commands ()
  "List `bin/magento' commands."
  (let ((output (magento2-cli--command-execute "list" "--format=json")))
    (delq nil
          (seq-map (lambda (command)
                     (let ((name (cdr-safe (assq 'name command))))
                       (when (and name (not (string-prefix-p "_" name)))
                         (list name :description (cdr-safe (assq 'description command))))))
                   (cdr-safe (assq 'commands (magento2-cli--parse-json-string output)))))))

(defun magento2-cli--completion-read-command ()
  "Completing read `bin/magento' command."
  (let* ((commands (magento2-cli--list-commands))
         (prompt "Magento 2 command: "))
    (if (fboundp 'consult--read)
        (let* ((max (seq-max (seq-map (lambda (cand) (length (car cand))) commands)))
               (align (propertize " " 'display `(space :align-to (+ left ,max 4))))
               (annotator (lambda (cand)
                            (when-let (description (plist-get (cdr-safe (assoc-string cand commands)) :description))
                              (concat align description)))))
          (consult--read commands
                         :prompt prompt
                         :annotate annotator))
      (completing-read prompt commands))))

;;; API

;;;###autoload
(defun magento2-cli (&optional command option)
  "Execute `bin/magento' COMMAND with OPTION arguments."
  (interactive "p")
  (when (called-interactively-p 'interactive)
    (setq command (magento2-cli--completion-read-command))
    (setq option (read-string (format "Input `magento2 %s' argument: " command))))
  (unless command
    (error "An argument COMMAND is required"))
  (let ((magento2-cli--quote-shell-argument nil)
        (magento2-cli--execute-interactive (member command magento2-cli-interactive-commands)))
    (apply (if magento2-cli--execute-interactive 'magento2-cli--command-execute 'magento2-cli--async-command-execute)
           command (list option))))

(provide 'magento2-cli)
;;; magento2-cli.el ends here
