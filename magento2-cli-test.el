;;; magento2-cli-test.el --- Tests for Magento 2 command-line interface -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Codemanufacture SLRS development

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

;;; Code:
(require 'magento2-cli)
(require 'ert)

(defvar magento2-cli--test-dir (if load-file-name
                           (file-name-directory load-file-name)
                         default-directory)
  "Directory containing the `magento2-cli' test files.")

(defun magento2-cli-test--load-file-to-string (path)
  "Load the content of a file into a string."
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

(ert-deftest magento2-cli-test--parse-json-string()
  "Test."
  (let ((output (magento2-cli--parse-json-string
                 (magento2-cli-test--load-file-to-string "tests/fixtures/magento2-cli-output.json"))))
    (should-not (equal nil (assoc 'commands output)))))

;;; magento2-cli-test.el ends here
