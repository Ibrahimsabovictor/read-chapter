;;; rename-chapter-test.el --- Tests for rename-chapter -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Blaine Mooers
;; License: GPL-3.0-or-later

;;; Commentary:

;; ERT test suite for the rename-chapter package.
;;
;; Run interactively:  M-x ert RET t RET
;; Run from the shell:
;;   emacs --batch -L . -l rename-chapter-test.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'rename-chapter)

;; ==================================================================
;; Test fixtures — helpers that create temporary directories and files
;; ==================================================================

(defmacro rename-chapter-test--with-sandbox (&rest body)
  "Execute BODY inside a fresh temporary directory.
Binds `sandbox' to the directory path (with trailing slash).
The directory and its contents are deleted afterwards."
  (declare (indent 0) (debug t))
  `(let ((sandbox (file-name-as-directory (make-temp-file "rc-test-" t))))
     (unwind-protect
         (progn ,@body)
       (delete-directory sandbox t))))

(defun rename-chapter-test--write (dir name contents)
  "Write a file NAME under DIR with CONTENTS.  Return the full path."
  (let ((path (expand-file-name name dir)))
    (make-directory (file-name-directory path) t)
    (with-temp-file path
      (insert contents))
    path))

;; ==================================================================
;; Unit tests: rename-chapter--title-from-file
;; ==================================================================

(ert-deftest rc-test-title-from-tex-chapter ()
  "Extract title from a LaTeX \\chapter{} command."
  (rename-chapter-test--with-sandbox
    (let ((f (rename-chapter-test--write
              sandbox "ch01.tex"
              "\\documentclass{book}\n\\begin{document}\n\\chapter{Introduction to Crystallography}\n\\end{document}\n")))
      (should (equal (rename-chapter--title-from-file f)
                     "Introduction to Crystallography")))))

(ert-deftest rc-test-title-from-org-heading ()
  "Extract title from an Org top-level heading."
  (rename-chapter-test--with-sandbox
    (let ((f (rename-chapter-test--write
              sandbox "ch01.org"
              "#+OPTIONS: toc:nil\n* Materials and Methods\nSome body text.\n")))
      (should (equal (rename-chapter--title-from-file f)
                     "Materials and Methods")))))

(ert-deftest rc-test-title-from-org-title-keyword ()
  "Extract title from #+TITLE: when no heading or \\chapter is present."
  (rename-chapter-test--with-sandbox
    (let ((f (rename-chapter-test--write
              sandbox "ch01.org"
              "#+TITLE: Results and Discussion\nSome prose.\n")))
      (should (equal (rename-chapter--title-from-file f)
                     "Results and Discussion")))))

(ert-deftest rc-test-title-from-file-nil-when-missing ()
  "Return nil when no chapter title is found."
  (rename-chapter-test--with-sandbox
    (let ((f (rename-chapter-test--write
              sandbox "empty.tex"
              "\\documentclass{article}\n\\begin{document}\nHello.\n\\end{document}\n")))
      (should (null (rename-chapter--title-from-file f))))))

(ert-deftest rc-test-title-chapter-beats-heading ()
  "\\chapter{} takes priority over a top-level Org heading."
  (rename-chapter-test--with-sandbox
    (let ((f (rename-chapter-test--write
              sandbox "mixed.org"
              "* Org Heading\n\\chapter{LaTeX Title}\n")))
      (should (equal (rename-chapter--title-from-file f)
                     "LaTeX Title")))))

;; ==================================================================
;; Unit tests: rename-chapter--resolve-file
;; ==================================================================

(ert-deftest rc-test-resolve-bare-name-to-tex ()
  "Resolve a bare name to a .tex file."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write sandbox "ch01.tex" "content")
    (should (string-suffix-p "ch01.tex"
                             (rename-chapter--resolve-file "ch01" sandbox)))))

(ert-deftest rc-test-resolve-bare-name-to-org ()
  "Resolve a bare name to a .org file when no .tex exists."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write sandbox "ch01.org" "content")
    (should (string-suffix-p "ch01.org"
                             (rename-chapter--resolve-file "ch01" sandbox)))))

(ert-deftest rc-test-resolve-with-extension ()
  "Resolve a name that already has an extension."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write sandbox "ch01.org" "content")
    (should (string-suffix-p "ch01.org"
                             (rename-chapter--resolve-file "ch01.org" sandbox)))))

(ert-deftest rc-test-resolve-with-subdir ()
  "Resolve a path with a subdirectory prefix."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write sandbox "Contents/ch01.tex" "content")
    (should (string-suffix-p "Contents/ch01.tex"
                             (rename-chapter--resolve-file "Contents/ch01" sandbox)))))

(ert-deftest rc-test-resolve-returns-nil-when-missing ()
  "Return nil when no candidate file exists."
  (rename-chapter-test--with-sandbox
    (should (null (rename-chapter--resolve-file "nonexistent" sandbox)))))

;; ==================================================================
;; Unit tests: rename-chapter--parse-include
;; ==================================================================

(defun rename-chapter-test--parse-line (text)
  "Insert TEXT into a temp buffer, place point on it, and parse."
  (with-temp-buffer
    (insert text)
    (goto-char (point-min))
    (rename-chapter--parse-include)))

(ert-deftest rc-test-parse-latex-include ()
  "Parse a LaTeX \\include{} statement."
  (let ((info (rename-chapter-test--parse-line
               "\\include{./Contents/ch03_methods}")))
    (should (equal (plist-get info :path) "./Contents/ch03_methods"))
    (should (eq    (plist-get info :style) 'latex))))

(ert-deftest rc-test-parse-latex-input ()
  "Parse a LaTeX \\input{} statement."
  (let ((info (rename-chapter-test--parse-line
               "\\input{chapters/intro}")))
    (should (equal (plist-get info :path) "chapters/intro"))
    (should (eq    (plist-get info :style) 'latex))))

(ert-deftest rc-test-parse-org-include ()
  "Parse an Org #+INCLUDE: statement."
  (let ((info (rename-chapter-test--parse-line
               "#+INCLUDE: \"./Contents/chapter1.org\"")))
    (should (equal (plist-get info :path) "./Contents/chapter1.org"))
    (should (eq    (plist-get info :style) 'org))))

(ert-deftest rc-test-parse-org-include-no-subdir ()
  "Parse an Org #+INCLUDE: without a subdirectory."
  (let ((info (rename-chapter-test--parse-line
               "#+INCLUDE: \"chapter1.org\"")))
    (should (equal (plist-get info :path) "chapter1.org"))
    (should (eq    (plist-get info :style) 'org))))

(ert-deftest rc-test-parse-error-on-plain-text ()
  "Signal an error when the line has no include statement."
  (should-error
   (rename-chapter-test--parse-line "Just some ordinary text.")
   :type 'user-error))

;; ==================================================================
;; Unit tests: rename-chapter--build-new-path
;; ==================================================================

(ert-deftest rc-test-build-latex-no-ext ()
  "LaTeX path without extension stays without extension."
  (should (equal (rename-chapter--build-new-path
                  "./Contents/ch03_methods" "MaterialsandMethods" 'latex)
                 "./Contents/MaterialsandMethods")))

(ert-deftest rc-test-build-latex-with-ext ()
  "LaTeX path with explicit .tex extension keeps it."
  (should (equal (rename-chapter--build-new-path
                  "./Contents/ch03.tex" "MaterialsandMethods" 'latex)
                 "./Contents/MaterialsandMethods.tex")))

(ert-deftest rc-test-build-org-with-ext ()
  "Org path preserves its .org extension."
  (should (equal (rename-chapter--build-new-path
                  "./Contents/chapter1.org" "MaterialsandMethods" 'org)
                 "./Contents/MaterialsandMethods.org")))

(ert-deftest rc-test-build-org-adds-ext ()
  "Org path without extension gets .org appended."
  (should (equal (rename-chapter--build-new-path
                  "chapter1" "MaterialsandMethods" 'org)
                 "MaterialsandMethods.org")))

(ert-deftest rc-test-build-no-subdir ()
  "Path without subdirectory produces a bare filename."
  (should (equal (rename-chapter--build-new-path
                  "ch03" "Introduction" 'latex)
                 "Introduction")))

;; ==================================================================
;; Unit tests: rename-chapter--clean-title
;; ==================================================================

(ert-deftest rc-test-clean-default-strips-spaces ()
  "Default settings strip all whitespace."
  (let ((rename-chapter-strip-regexp "\\s-+")
        (rename-chapter-strip-replacement ""))
    (should (equal (rename-chapter--clean-title "Materials and Methods")
                   "MaterialsandMethods"))))

(ert-deftest rc-test-clean-underscore-replacement ()
  "Underscores as replacement character."
  (let ((rename-chapter-strip-regexp "\\s-+")
        (rename-chapter-strip-replacement "_"))
    (should (equal (rename-chapter--clean-title "Materials and Methods")
                   "Materials_and_Methods"))))

(ert-deftest rc-test-clean-hyphen-replacement ()
  "Hyphens as replacement character."
  (let ((rename-chapter-strip-regexp "\\s-+")
        (rename-chapter-strip-replacement "-"))
    (should (equal (rename-chapter--clean-title "Results and Discussion")
                   "Results-and-Discussion"))))

(ert-deftest rc-test-clean-no-whitespace ()
  "Title without whitespace is returned unchanged."
  (let ((rename-chapter-strip-regexp "\\s-+")
        (rename-chapter-strip-replacement ""))
    (should (equal (rename-chapter--clean-title "Introduction")
                   "Introduction"))))

;; ==================================================================
;; Integration tests: rename-chapter (the full command)
;; ==================================================================

(ert-deftest rc-test-integration-latex-include ()
  "Full round-trip: LaTeX \\include with subdirectory."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write
     sandbox "Contents/ch03_methods.tex"
     "\\chapter{Materials and Methods}\n\\label{ch:methods}\n")
    ;; Create a main file that includes the chapter.
    (let ((main (rename-chapter-test--write
                 sandbox "main.tex"
                 "\\documentclass{book}\n\\include{Contents/ch03_methods}\n")))
      (with-current-buffer (find-file-noselect main)
        (goto-char (point-min))
        (forward-line 1)                ; move to the \include line
        (rename-chapter)
        ;; Buffer should be updated.
        (should (string-match-p "MaterialsandMethods" (buffer-string)))
        ;; Old file should be gone; new file should exist.
        (should (not (file-exists-p
                      (expand-file-name "Contents/ch03_methods.tex" sandbox))))
        (should (file-exists-p
                 (expand-file-name "Contents/MaterialsandMethods.tex" sandbox)))
        (kill-buffer)))))

(ert-deftest rc-test-integration-latex-input ()
  "Full round-trip: LaTeX \\input without subdirectory."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write
     sandbox "intro.tex"
     "\\chapter{Introduction to Crystallography}\n")
    (let ((main (rename-chapter-test--write
                 sandbox "main.tex"
                 "\\input{intro}\n")))
      (with-current-buffer (find-file-noselect main)
        (goto-char (point-min))
        (rename-chapter)
        (should (string-match-p "IntroductiontoCrystallography"
                                (buffer-string)))
        (should (file-exists-p
                 (expand-file-name "IntroductiontoCrystallography.tex" sandbox)))
        (should (not (file-exists-p
                      (expand-file-name "intro.tex" sandbox))))
        (kill-buffer)))))

(ert-deftest rc-test-integration-org-include ()
  "Full round-trip: Org #+INCLUDE with subdirectory."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write
     sandbox "Contents/chapter1.org"
     "* Introduction to Crystallography\nSome text.\n")
    (let ((main (rename-chapter-test--write
                 sandbox "main.org"
                 "#+INCLUDE: \"Contents/chapter1.org\"\n")))
      (with-current-buffer (find-file-noselect main)
        (goto-char (point-min))
        (rename-chapter)
        (should (string-match-p "IntroductiontoCrystallography\\.org"
                                (buffer-string)))
        (should (file-exists-p
                 (expand-file-name "Contents/IntroductiontoCrystallography.org"
                                   sandbox)))
        (should (not (file-exists-p
                      (expand-file-name "Contents/chapter1.org" sandbox))))
        (kill-buffer)))))

(ert-deftest rc-test-integration-org-title-keyword ()
  "Full round-trip: Org file whose title comes from #+TITLE:."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write
     sandbox "results.org"
     "#+TITLE: Results and Discussion\nBody.\n")
    (let ((main (rename-chapter-test--write
                 sandbox "main.org"
                 "#+INCLUDE: \"results.org\"\n")))
      (with-current-buffer (find-file-noselect main)
        (goto-char (point-min))
        (rename-chapter)
        (should (string-match-p "ResultsandDiscussion\\.org"
                                (buffer-string)))
        (should (file-exists-p
                 (expand-file-name "ResultsandDiscussion.org" sandbox)))
        (kill-buffer)))))

(ert-deftest rc-test-integration-custom-replacement ()
  "Full round-trip: underscore replacement via customization."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write
     sandbox "ch01.tex"
     "\\chapter{Materials and Methods}\n")
    (let ((main (rename-chapter-test--write
                 sandbox "main.tex"
                 "\\include{ch01}\n"))
          (rename-chapter-strip-regexp "\\s-+")
          (rename-chapter-strip-replacement "_"))
      (with-current-buffer (find-file-noselect main)
        (goto-char (point-min))
        (rename-chapter)
        (should (string-match-p "Materials_and_Methods" (buffer-string)))
        (should (file-exists-p
                 (expand-file-name "Materials_and_Methods.tex" sandbox)))
        (kill-buffer)))))

;; ==================================================================
;; Error-path tests
;; ==================================================================

(ert-deftest rc-test-error-no-include-on-line ()
  "Signal user-error when line has no include statement."
  (with-temp-buffer
    (insert "Just some text.\n")
    (goto-char (point-min))
    (should-error (rename-chapter) :type 'user-error)))

(ert-deftest rc-test-error-file-not-found ()
  "Signal user-error when the referenced file does not exist."
  (rename-chapter-test--with-sandbox
    (let ((main (rename-chapter-test--write
                 sandbox "main.tex"
                 "\\include{nonexistent_chapter}\n")))
      (with-current-buffer (find-file-noselect main)
        (goto-char (point-min))
        (should-error (rename-chapter) :type 'user-error)
        (kill-buffer)))))

(ert-deftest rc-test-error-no-title-in-file ()
  "Signal user-error when the chapter file has no title."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write
     sandbox "empty.tex"
     "\\documentclass{article}\nHello.\n")
    (let ((main (rename-chapter-test--write
                 sandbox "main.tex"
                 "\\include{empty}\n")))
      (with-current-buffer (find-file-noselect main)
        (goto-char (point-min))
        (should-error (rename-chapter) :type 'user-error)
        (kill-buffer)))))

(ert-deftest rc-test-error-target-exists ()
  "Signal user-error when the target filename already exists."
  (rename-chapter-test--with-sandbox
    (rename-chapter-test--write
     sandbox "ch01.tex"
     "\\chapter{Intro}\n")
    ;; Pre-create the target so the rename would clobber it.
    (rename-chapter-test--write sandbox "Intro.tex" "occupant")
    (let ((main (rename-chapter-test--write
                 sandbox "main.tex"
                 "\\include{ch01}\n")))
      (with-current-buffer (find-file-noselect main)
        (goto-char (point-min))
        (should-error (rename-chapter) :type 'user-error)
        (kill-buffer)))))

(provide 'rename-chapter-test)
;;; rename-chapter-test.el ends here