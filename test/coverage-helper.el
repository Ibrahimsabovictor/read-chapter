;;; coverage-helper.el --- Bootstrap undercover.el for rename-chapter -*- lexical-binding: t; -*-

;;; Commentary:

;; This file is loaded BEFORE the test file when running `make coverage'.
;; It configures undercover.el to instrument rename-chapter.el and write
;; an LCOV report to coverage/lcov.info.
;;
;; When running on a CI service (GitHub Actions, Travis, etc.) undercover
;; automatically detects the environment and can post results to
;; Coveralls or Codecov instead.
;;
;; If undercover is not installed the file silently does nothing, so
;; `make test' keeps working without it.

;;; Code:

(when (require 'undercover nil t)
  ;; Local runs  → write LCOV to coverage/lcov.info
  ;; CI runs     → undercover auto-detects and posts to Coveralls/Codecov
  (let ((report-dir (expand-file-name "coverage"
                                       (locate-dominating-file "." "Makefile"))))
    (unless (file-directory-p report-dir)
      (make-directory report-dir t))
    (undercover "rename-chapter.el"
                (:report-file (expand-file-name "lcov.info" report-dir))
                (:report-format 'lcov)
                (:send-report nil))))       ; set to t for Coveralls/Codecov

(provide 'coverage-helper)
;;; coverage-helper.el ends here