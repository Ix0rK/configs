;;; Enable lexical binding -*- lexical-binding: t -*-
;;Lexical binding enables using variables defined with let in lambda functions called later
;;; Package management
;;;; Optimize garbage collection : improves the startup time
(setq gc-cons-threshold 64000000)
(add-hook 'after-init-hook #'(lambda ()(setq gc-cons-threshold 800000)))

;;;; Enable MELPA : Add the main user repository of packages
;; cf Getting Started https://melpa.org/
;; ELPA, the default repository, has much less available
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl
    (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat "http" "://melpa.org/packages/")) t)
  (add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives (cons "gnu" (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)

;;;; use-package : Use package will be used as a package loader in this file
;; Install use-package if not installed yet
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Install the package if not available yet
(use-package use-package
  :custom
  (use-package-always-ensure t) ; Download missing packages by default
  (use-package-always-defer t) ; Lazy load by default, use :demand otherwise
)

;;;; diminish : Hide the mode line string for modes (called the lighter)
(use-package diminish
  :demand
  :config
  (diminish 'eldoc-mode)
  (diminish 'abbrev-mode))

;;;; esup : Launch the esup command to measure startup time of each emacs plugin
(use-package esup
  :custom (esup-depth 0)) ; Sometimes fixes the bug https://github.com/jschaf/esup/issues/54

;;; Various customizations options
;;;; my-keys minor mode for global keybindings overriding
(define-minor-mode my-keys-mode
  "Minor mode to enable custom keybindings"
  :lighter ""
  :global t
  :keymap '())
(my-keys-mode)

;;;; Main color theme : vscode-dark-plus-theme
(use-package vscode-dark-plus-theme
  :demand
  :config (load-theme 'vscode-dark-plus t))

;;;; Mode line theme : doom mode line
(use-package doom-modeline
  :demand
  :custom-face
  (mode-line ((t :background "black")))
  (mode-line-inactive ((t :background "#333333"))) ; Dark grey
  :custom
  (doom-modeline-unicode-fallback t)
  :init
  (doom-modeline-mode))

;;;; All the icons
;; TODO on 1st install : use all-the-icons-install-fonts
;; Caskaydia => https://www.nerdfonts.com/font-downloads
;; Symbola => https://fontlibrary.org/fr/font/symbola
(use-package all-the-icons
  :if (display-graphic-p))

;;;; Dired as default buffer
(when (< (length command-line-args) 2)
  (add-hook 'after-init-hook 'dired-jump))

;;;; Dashboard as default buffer
(use-package dashboard
  :disabled
  :demand
  :hook (dashboard-mode . (lambda()(setq-local show-trailing-whitespace nil)))
  :diminish dashboard-mode
  :custom (dashboard-items '((projects . 5)
                             (bookmarks . 10)
                             (recents  . 10)))
  :config
  (dashboard-setup-startup-hook))

;;;; Misc
(progn
  (tool-bar-mode 0) ; Disable the toolbar in GUI mode
  (when (display-graphic-p) (scroll-bar-mode 0)) ; Disable the scroll bar in GUI mode
  (setq inhibit-startup-screen t) ; Hide the startup screen
  (savehist-mode) ; Save history for commands
  (setq isearch-resume-in-command-history t) ; Use history for isearch as well
  (global-auto-revert-mode) ; Refresh files automatically when modified from outside emacs
  (setq enable-local-eval t) ; Enable eval blocks in .dir-locals.el
  (setq enable-local-variables :all) ; Enable by default variables in .dir-locals.el
  (setq ring-bell-function 'ignore) ; Disable the bell for emacs
  (setq debug-on-error nil) ; Display the stacktrace if error encountered in one of the lisp method
  (setq completions-detailed t) ; Detailed description for the built in describe symbol etc
  (column-number-mode t) ; Display column numbers in the status line
  (global-display-line-numbers-mode t) ; Display line numbers on the left
  (line-number-mode t) ; Display line number
  (size-indication-mode t) ; Display size indication
  (delete-selection-mode 1) ; If text is selected, we expect that typing will replace the selection
  (show-paren-mode 1) ; Highlight the matching parenthesis
  (setq-default show-trailing-whitespace t) ; Show in red the spaces forgotten at the end of lines
  (setq-default indent-tabs-mode nil) ; Use spaces for indent
  (setq next-error-message-highlight t) ; When jumping between errors, occurs, etc, highlight the current line
  (menu-bar-mode -1) ; Hide Menu bar
  (setq use-short-answers t) ; Abreviate Yes/No to y or n
  (setq default-tab-width 4) ; Number of spaces inserted by tab
  (setq-default c-basic-offset  4) ; Base indent size when indented automatically
  (c-set-offset 'cpp-macro 0 nil) ; Indent C/C++ macros as normal code
  (c-set-offset 'substatement-open 0) ; Align braces with the if/for statement. If not set, a half indent will be used
  (c-set-offset 'arglist-intro '+) ; Align multiline arguments with a standard indent (instead of with parenthesis)
  (c-set-offset 'arglist-close 0) ; Align the parenthesis at the end of the arguments with the opening statement indent
  (setq make-backup-files nil) ; Do not use backup files (filename~)
  (setq create-lockfiles nil)) ; Do not use lock files (.#filename)

;;;; rename-file-and-buffer(name)
(defun rename-file-and-buffer (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME."
  (interactive "sNew name: ")
  (when (get-buffer new-name)
    (error "A buffer named '%s' already exists!" new-name))
  (when (buffer-file-name)
    (rename-file (buffer-file-name) new-name t)
    (set-visited-file-name new-name))
  (rename-buffer new-name)
  (set-buffer-modified-p nil))

;;;; switch-to-last-buffer
(defun switch-to-last-buffer()
  "Use `switch-to-buffer' to visit the last buffer"
  (interactive)
  (switch-to-buffer nil))

;;;; delete-start-or-previous-line
(defun delete-start-or-previous-line()
  "Use `kill-line' to delete either the start of the line, or the previous line if empty"
  (interactive)
  (kill-line (if (= (line-beginning-position) (point)) -1 0)))

;;;; match-buffer-extension
(defun match-buffer-extension(&rest extensions)
  "Returns t if the current buffer has an extension in EXTENSIONS"
  (if (member (file-name-extension (buffer-name)) extensions)
      t))

;;; Compilation options
;;;; Compilation misc
(use-package compile
  :ensure nil ; Emacs built in
  :hook (compilation-mode . (lambda()(setq show-trailing-whitespace nil)))
  :custom
  (compilation-always-kill t) ; Do not ask for confirmation when I stop current compilation
  (compilation-message-face 'all-the-icons-green))

;;;; switch-to-compilation-other-window()
(defun switch-to-compilation-other-window()
  "Switches to the compilation buffer in another window"
  (interactive)
  (unless (string-equal "*compilation*" (buffer-name))
    (switch-to-buffer-other-window "*compilation*")))

(defun switch-to-compilation-other-window-end()
  "Switches to the compilation buffer in another window and go to buffer end"
  (interactive)
  (switch-to-compilation-other-window)
  (end-of-buffer))

;;;; recompile-switch
(defun recompile-switch()
  "Uses the recompile function and switches to the buffer end"
  (interactive)
  (recompile)
  (switch-to-compilation-other-window-end))

;;;; compile-all
(defcustom compile-all-command nil
  "If non nil, `compile-all' will use it as command instead of `compile-command'
This can be useful in conjunction to projectile's .dir-locals variables"
  :type 'string
  :risky nil)

(defun compile-all()
  "Compiles the whole project and switch to buffer end"
  (interactive)
  (compile (or compile-all-command "make -j8"))
  (switch-to-compilation-other-window-end))

;;;; compile-file
(defun compile-file(file-name)
  "Compiles the file FILE-NAME using a command to be define `compile-file-command'
  This function should take a filename as parameter and returning the command as output"
  (interactive (list (buffer-file-name)))
  (unless (fboundp 'compile-file-command)
    (error "compile-file expects the compile-file-command function to be defined"))
  (compile (compile-file-command file-name))
  (switch-to-compilation-other-window-end))

;;;; ansi-color : Translate TTY escape sequences into colors
(defun ansi-color-compilation-filter-except-ag()
  "Like `ansi-color-compilation-filter', except on buffers generated by the ag package.
   If we use vanilla ansi-color-compilation-filter, the colors get messed up"
  (unless (string-match "ag search text" (buffer-name))
    (ansi-color-compilation-filter)))

(use-package ansi-color
  :ensure nil ; Emacs built-in
  :hook (compilation-filter . ansi-color-compilation-filter-except-ag)) ; Handle terminal colors in the compilation buffer

;;;; regexps : Set compilation regex for errors
(let ((enabled-regexps ())
      (custom-error-list '(
        ;; Insert your custom regexps here
        (link-error "^\\(.*\\):\\([0-9]+\\): undefined reference to.*$" 1 2)
        (jest-error "^.*\(\\(.*\\):\\([0-9]+\\):\\([0-9]+\\)\).*$" 1 2 3)
        (gcc-error "^[ ]*\\(.*\\):\\([0-9]+\\):\\([0-9]+\\): \\(.*error:\\|  required from here\\).*$" 1 2 3)
        (gcc-warning "^\\(.*\\):\\([0-9]+\\):\\([0-9]+\\): warning:.*$" 1 2 3 1)
        (gcc-info "^\\(.*\\):\\([0-9]+\\):\\([0-9]+\\): note:.*$" 1 2 3 0)
        (qt-test "^   Loc: \\[\\(.*\\)\(\\([0-9]+\\)\)\\]$" 1 2)
        (python-unittest "^  File \"\\(.*\\)\", line \\([0-9]+\\),.*$" 1 2))))
  (dolist (err custom-error-list)
    (add-to-list 'enabled-regexps (car err)))
  (custom-set-variables `(compilation-error-regexp-alist ',enabled-regexps))
  (add-hook 'compilation-mode-hook (lambda()
    (dolist (err custom-error-list)
      (add-to-list 'compilation-error-regexp-alist-alist err)))))

;;; General usage packages
;;;; magit : Git front end (amazing!)
(use-package magit
  :custom-face (magit-filename ((t :foreground "white"))) ; Otherwise untracked files have the same color as title in git status
  :custom
  (magit-no-confirm t) ; Do not ask for confirmation for actions
  (magit-visit-ref-behavior '(checkout-any focus-on-ref))) ; Enter on branch names makes you checkout the branch

;;;; ediff : Built in side by side diffs of files
(use-package ediff
  :ensure nil ; Built-in
  :hook (ediff-keymap-setup . (lambda()
                        (define-key ediff-mode-map "h"  'ediff-status-info)
                        (define-key ediff-mode-map "i" 'ediff-previous-difference)
                        (define-key ediff-mode-map "k" 'ediff-next-difference)))
  :custom
  (ediff-split-window-function 'split-window-horizontally)) ; Make ediff split side by side

;;;; which-key : Displays command shortcuts when typing commands
(use-package which-key
  :demand
  :config (which-key-mode)
  :diminish)

;;;; key-chord  : Enables combination of keys like zz
(use-package key-chord
  :demand
  :custom (key-chord-two-keys-delay 0.03)
  :config (key-chord-mode))

;;;; hydra : Keybindings combinations
(use-package hydra)

;;;; Vertico : Completion for commands in a vertical way
(use-package vertico
  :init (vertico-mode)
  :hook (completion-list-mode . (lambda()(setq-local show-trailing-whitespace nil)))  ; Disable whitespace check in completion buffers (e.g M-:)
  :bind (("C-k" . vertico-next))
  :custom-face
  (vertico-current ((t (:background "#264f78")))) ; Current selected item shown as blue
  :custom
  (vertico-cycle t)
  (vertico-count 15))

;;;; Marginalia : Display additional completion data (doc strings, file permissions...)
(use-package marginalia
  :init (marginalia-mode)
  :custom-face
  (completions-annotations ((t (:inherit 'shadow))))) ; Disable italic since it is translated to underline in terminal

;;;; Orderless : Matching of several patterns without order in completion
(use-package orderless
  :custom-face
  (orderless-match-face-0 ((t (:weight bold :foreground "gold1")))) ; Display the first matching part as yellow gold
  :custom
  ((completion-styles '(orderless basic))
   (completion-category-defaults nil)
   (completion-category-overrides '((file (styles partial-completion))))))

;;;; Consult : a collection of commands that improve emacs defaults
(use-package consult
  :bind (:map my-keys-mode-map
         ("M-y" . consult-yank-pop)
         :map help-map
         ("a" . consult-apropos)
         :map ctl-x-map
         ("b" . consult-buffer))
  :config
  (recentf-mode))

;;;; Expand Region : expand or contract selection
(use-package expand-region)

;;;; Helpful : nice looking and more complete help buffers
(use-package helpful
  :bind (:map help-map
              ("p" . helpful-at-point)
              ("s" . helpful-symbol)
              ("v" . helpful-variable)
              ("f" . helpful-callable)
              ("k" . helpful-key)))

;;;; Dired : built-in navigation of folders
(use-package dired
  :ensure nil  ; emacs built-in
  :bind (:map dired-mode-map ("u" . dired-up-directory))
  :custom(dired-kill-when-opening-new-dired-buffer t)) ; Auto close previous folder buffer

;;;; Org mode : Base mode for note taking
(use-package org
  :custom-face
  (org-warning ((t (:underline nil)))) ; Do not underline org-warnings, red is enough
  (org-document-title ((t (:weight bold :height 1.3))))
  (org-level-1        ((t (:height 1.2))))
  (org-level-2        ((t (:height 1.1))))
  (org-block          ((t (:inherit 'fixed-pitch))))
  :custom ((org-agenda-files '("~/.org_roam")) ; For autopopulating todos from notes
           (org-agenda-span 'month) ; To have a monthly view by default
           (org-agenda-start-on-weekday 1) ; Agenda starts on monday in agenda
           (calendar-week-start-day 1) ; Date picker starts on monday
           (org-capture-bookmark nil) ; To disable adding a bookmark on each org capture
           (org-deadline nil)) ; To disable adding a bookmark on each org capture
  :hook (org-mode . (lambda()
                      (require 'org-tempo) ; For templates like <sTAB to insert a code block
                      (require 'recentf)
                      (add-to-list 'recentf-exclude ".*org$") ; Ignore org files from recentf due to agenda loading everything
                      (org-indent-mode) ; Auto indent lines according to depth
                      (auto-fill-mode)))) ; Wrap lines when longer than fill column
(setq
 org-src-lang-modes ())
;;;; Org org-agenda-other-window-no-switch()
(defun org-agenda-other-window-no-switch()
  "Opens the org agenda (monthly view) in a side window without leaving the current window"
  (interactive)
  (save-selected-window (org-agenda-list)))

;;;; Org bullets : Pretty mode for org
(use-package org-bullets
  :hook (org-mode . org-bullets-mode))

;;;; org-roam : Notes organizing
(use-package org-roam
  :init
  (setq org-roam-v2-ack t)
  :config
  (org-roam-db-autosync-mode)
  :custom
  (org-return-follows-link t)
  (org-roam-directory "~/.org_roam")
  (org-roam-completion-everywhere t))

(defun org-roam-pull-commit-push()
  "Git commit and push all the modified files in `org-roam-directory'"
  (interactive)
  (let ((default-directory org-roam-directory))
    (shell-command "git add -u")
    (shell-command "git commit -m 'Automated commit from org-roam-commit-and-push'" )
    (shell-command "git pull --rebase" )
    (shell-command "git push" )))

;;;; visual-fill-column : Center text in the window and wrap around fill-column
(use-package visual-fill-column
  :custom ((visual-fill-column-width 130)
           (visual-fill-column-center-text t)))

;;;; org-present : Using org files for powerpoints
(setq my/original-default_face 'default)
(defun my/org-present-start()
  "To be called when enabling `org-present-mode' : sets up the various presentation options"
  (setq-local face-remapping-alist '((default (:height 1.5) variable-pitch)
                                     (header-line (:height 4.5) variable-pitch)
                                     (org-code (:height 1.55) org-code)
                                     (org-verbatim (:height 1.55) org-verbatim)
                                     (org-block (:height 1.25) org-block)
                                     (org-block-begin-line (:height 0.7) org-block)))
(setq-local header-line-format " ")
  (visual-fill-column-mode 1)
  (visual-line-mode 1)
  (global-display-line-numbers-mode 0))

(defun my/org-present-end()
p  "To be called when leaving `org-present-mode' : disables the various presentation options"
(setq-local header-line-format nil)
  (setq-local face-remapping-alist nil)
  (visual-fill-column-mode 0)
  (global-display-line-numbers-mode 1))

(use-package org-present
  :hook ((org-present-mode      . my/org-present-start)
         (org-present-mode-quit . my/org-present-end))
  :bind (:map org-present-mode-keymap
         ("C-c C-h" . org-present-hide-cursor)))

;;; Development packages and options
;;;; ag and projectile-ag : Front end for the CLI utility ag
(use-package ag
  :custom (ag-highlight-search t))

;;;; Projectile : git project functions, like the built in project but better
(use-package projectile)

;;;; rainbow-delimiters : Parenthesis color based on depth
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;;; treemacs : Displays the current project on the left as in an IDE
(use-package treemacs
  :custom (treemacs-no-delete-other-windows nil))

;;;; web-mode : Support various web files
(use-package web-mode
  :mode ("\\.css\\'" "\\.html\\'" "\\.ts\\'" "\\.js\\'" "\\.vue\\'")
  :hook
  (web-mode . (lambda () (when (match-buffer-extension "ts" "js" "vue")
                           (lsp-deferred)
                           (setq-local lsp-auto-format t))))
  :custom
  (web-mode-script-padding 0) ; For vue.js SFC : no initial padding in the script section
  (web-mode-markup-indent-offset 2)) ; For html : use an indent of size 2 (default is 4)

;;;; prettier-js : Formatting on save, used by my-ts-mode for .js and .ts files
(use-package prettier-js
  :custom
  (prettier-js-show-errors nil)
  (prettier-js-args '("--semi" "false"
                      "--single-quote" "false"
                      "--tab-width" "4"
                      "--trailing-comma" "all"
                      "--print-width" "150")))

;;;; Outline mode with package outline-minor-faces and outshine
;;;;; Enable sane bindings and actions for outline mode
(use-package outline
  :ensure nil ; emacs built-in
  :hook
  (emacs-lisp-mode . outline-minor-mode)
  (outline-minor-mode . (lambda()(diminish 'outline-minor-mode)))
  :custom
  (outline-minor-mode-cycle t)) ; Tab and S-Tab cycle between different visibility settings

;;;;; Pretty colors for headings
;; We don't use (outline-minor-mode-highlight 'override) because it applies to some non headings as well
(use-package outline-minor-faces
  :hook (outline-minor-mode . outline-minor-faces-add-font-lock-keywords))

;;;; csv-mode : Support for csv files (use csv-align-mode for alignment)
(use-package csv-mode
  :mode "\\.csv\\'")

;;;; yaml-mode : Support gitlab-ci.yml
(use-package yaml-mode
  :mode "\\.yml\\'")

;;;; hide-show-mode : Hide/show sections of code : current function, class, or if/else section
(use-package hideshow
  :ensure nil ; Built-in emacs
  :hook (prog-mode . (lambda()
                       (hs-minor-mode)
                       (diminish hs-minor-mode))))

;;;; include-guards(text) : Add include guards to the current file
(defun include-guards(text)
  "Adds include guards in the current file, useful for C/C++ devs
It will add the following code :
     #ifndef TEXT
     #define TEXT
     // Current file content
     #endif //TEXT
"
  (interactive
   (list
    (let* ((default (replace-regexp-in-string "\\." "_" (upcase (buffer-name))))
           (prompt (format "Include guard text (default %s): " default)))
      (read-string prompt nil  nil default))))
  (save-excursion
    (goto-char 0)
    (insert (format "#ifndef %s\n#define %s\n" text text))
    (goto-char (max-char))
    (insert (format "#endif // %s" text))
    ))

;;;; include-c-header-val() : Inserts a #include directive for C/C++
(defun include-c-header(val)
  "Adds a #include \"VAL.h\" at point and saves the file"
  (interactive "MHeader file name: ")
  (insert (format "#include \"%s.h\"\n" val))
  (save-buffer))

;;;; c++ mode
(use-package c++-mode
  :ensure nil  ; Part of emacs
  :mode ("\\.h\\'" "\\.cpp\\'" "\\.hpp\\'" "\\.hxx\\'" "\\.cxx\\'")
  :hook (c++-mode . lsp-deferred)
  :config
  (advice-add 'c-update-modeline :override #'ignore)) ;; Don't use a modeline suffix (i.e C++//l)


;;; LSP + DAP : completion, linting, debugging
;;;; lsp-treemacs : treemacs style views for various lsp results
(use-package lsp-treemacs)

;;;; company : Completion frontend, used by lsp
(use-package company
  :diminish
  :hook (emacs-lisp-mode . company-mode))

;;;; yasnippet : Dependency used by lsp to insert snippets. Used by some lsp commands like completion
(use-package yasnippet
  :hook (lsp-mode . (lambda()
                      (yas-minor-mode)
                      (diminish 'yas-minor-mode))))

;;;; dap-mode : Debug adapter protocol for emacs
;; For c++ Install mono on linux then run dap-cpptools-setup for c++
;; For dap-firefox : download and unzip the package in ~/.emacs.d/.extension/vscode/
;; and modify the path to the executable js file which has been renamed to adapter.bundle.js
;; For any language, require then the appropriate packages, and use a launch.json at your lsp root
(use-package dap-mode
  :hook
  (c++-mode . (lambda()(require 'dap-cpptools)))
  (python-mode . (lambda()(require 'dap-python)))
  (web-mode . (lambda()(require 'dap-firefox))))

;; UI settings for dap-mode (comes with the dap-mode package)
(use-package dap-ui
  :ensure nil
  :config
  (unless (display-graphic-p)
    (set-face-background 'dap-ui-marker-face "color-166") ; An orange background for the line to execute
    (set-face-attribute 'dap-ui-marker-face nil :inherit nil) ; Do not inherit other styles
    (set-face-background 'dap-ui-pending-breakpoint-face "blue") ; Blue background for breakpoints line
    (set-face-attribute 'dap-ui-verified-breakpoint-face nil :inherit 'dap-ui-pending-breakpoint-face)))


;;;; flycheck : Syntax highlighting, used by lsp
(use-package flycheck
  ;; Add a flake8 for python. Needs to be done after lsp-diagnostics has been loaded
  :hook (lsp-diagnostics-mode . (lambda()(flycheck-add-next-checker 'lsp 'python-flake8))))

;;;; lsp-mode : Completion and syntax highlighting backend API, available for most languages
;; The following packages need to be installed according to the language
;; Python : pip install pyright flake8
;; c++ : pacman -S clang bear (or jq)
;; vue.js, javascript, typescript : sudo npm install -g vls typescript-language-server

(use-package lsp-ui
  :commands lsp-ui-mode)

(use-package lsp-pyright
  :hook (python-mode . (lambda () (require 'lsp-pyright)))
  :init (when (executable-find "python3")
          (setq lsp-pyright-python-executable-cmd "python3")))


(use-package lsp-mode
  :hook ((python-mode) . lsp-deferred)
  :commands lsp
  :config
  (setq lsp-auto-guess-root t)
  (setq lsp-log-io nil)
  (setq lsp-restart 'auto-restart)
  (setq lsp-enable-symbol-highlighting nil)
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-signature-auto-activate nil)
  (setq lsp-signature-render-documentation nil)
  (setq lsp-eldoc-hook nil)
  (setq lsp-modeline-code-actions-enable nil)
  (setq lsp-modeline-diagnostics-enable nil)
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-semantic-tokens-enable nil)
  (setq lsp-enable-folding nil)
  (setq lsp-enable-imenu nil)
  (setq lsp-enable-snippet nil)
  (setq read-process-output-max (* 1024 1024)) ;; 1MB
  (setq lsp-idle-delay 0.5)
  (setq lsp-headerline-arrow ">")) ; Material design icon not working on windows

;;;; lsp-format-and-save : format on save if lsp-auto-format is not nil
(defcustom lsp-auto-format nil
  "If not nil, lsp-format-and-save will format the buffer before saving"
   :type 'boolean)

(defun lsp-format-and-save()
  "Saves the current buffer and formats it if lsp-format-on-save is not nil"
  (interactive)
  (when (and (not buffer-read-only) lsp-auto-format)
    (lsp-format-buffer))
  (save-buffer))

;;; Reimplementation of a mark ring
;;;; Define the global variables used
(defvar global-mark-previous ()
  "List containing previous mark positions, combining the ideas of `mark-ring'  and `global-mark-ring'.
This mark-ring will record all mark positions globally, multiple times per buffer")

(defvar global-mark-next ()
  "List containing next mark positions, used to revert the effects of `global-mark-previous'")

(defvar bidirectional-mark-ring-max 40
  "Maximum size of `global-mark-previous'.  Start discarding off end if gets this big.")

;;;; Override pushmark
(defun bidirectional-push-mark-advice(&optional location nomsg activate)
  (interactive)
  (when (mark t)
    (let ((old (nth bidirectional-mark-ring-max global-mark-previous))
          (history-delete-duplicates nil))
      (add-to-history 'global-mark-previous (copy-marker (mark-marker)) bidirectional-mark-ring-max)
      (setq global-mark-next ()) ; Reset the global mark next when the user performs other actions
      (when old
        (set-marker old nil)))))

(advice-add 'push-mark :after #'bidirectional-push-mark-advice)

;;;; mark manipulation utilities
(defun marker-is-point-p (marker)
  "Tests if MARKER is current point"
  (and (eq (marker-buffer marker) (current-buffer))
       (= (marker-position marker) (point))))

(defun jump-to-marker(marker)
  "Jumps to the given MARKER buffer/position"
  (let* ((buffer (marker-buffer marker))
	 (position (marker-position marker)))
    (set-marker (mark-marker) marker)
    (set-buffer buffer)
    (goto-char position)
    (when (hs-overlay-at position)
      (hs-show-block)
      (goto-char position))
    (switch-to-buffer buffer)))

;;;; bakckward-mark() : main back function
(defun backward-mark()
  "Records the current position at mark and jump to previous mark"
  (interactive)
  (let* ((target (car global-mark-previous))
         (current target))
    (cond ((not current) (setq target nil))
          ((marker-is-point-p current) (setq target (car (cdr global-mark-previous))))
          (t (push-mark)))
    (if (not target)
        (user-error "No previous mark position")
      (push (copy-marker (mark-marker)) global-mark-next)
      (pop global-mark-previous)
      (jump-to-marker (car global-mark-previous)))))

;;;; forward-mark() : main next function
(defun forward-mark()
  "Records the current position at mark and jump to previous mark"
  (interactive)
  (let* ((target (car global-mark-next))
         (prev (car global-mark-previous)))
    (if (not target)
        (user-error "No next mark position")
      (unless (and prev (marker-is-point-p prev))
        (push-mark))
      (push (copy-marker target) global-mark-previous)
      (pop global-mark-next)
      (jump-to-marker target))))

;;; Add plantuml
(use-package plantuml-mode)

(setq org-plantuml-jar-path (expand-file-name "/home/ilankeller/Documents/App/plantuml.jar"))
(add-to-list 'org-src-lang-modes '("plantuml" . plantuml))
(org-babel-do-load-languages 'org-babel-load-languages '((plantuml . t)))

;; Sample jar configuration
    (setq plantuml-jar-path "/home/ilankeller/Documents/App/plantuml.jar")
    (setq plantuml-default-exec-mode 'jar)

    ;; Sample executable configuration
    (setq plantuml-executable-path "/home/ilankeller/Documents/App/plantuml.jar")
    (setq plantuml-default-exec-mode 'executable)
(add-to-list 'auto-mode-alist '("\\.plantuml\\'" . plantuml-mode))
;;; Custom section : modified when experimenting with the customize menu.
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(compilation-error-regexp-alist
   '(python-unittest qt-test gcc-info gcc-warning gcc-error jest-error link-error))
 '(ispell-dictionary nil)
 '(package-selected-packages
   '(move-text lsp-ui eglot flycheck-plantuml yasnippet yaml-mode which-key web-mode vscode-dark-plus-theme visual-fill-column vertico use-package rainbow-delimiters projectile prettier-js plantuml-mode outline-minor-faces org-roam org-present org-bullets orderless marginalia magit lsp-pyright key-chord helpful flycheck expand-region esup doom-modeline diminish dap-mode csv-mode consult company all-the-icons ag)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(completions-annotations ((t (:inherit 'shadow))))
 '(magit-filename ((t :foreground "white")))
 '(mode-line ((t :background "black")))
 '(mode-line-inactive ((t :background "#333333")))
 '(orderless-match-face-0 ((t (:weight bold :foreground "gold1"))))
 '(org-block ((t (:inherit 'fixed-pitch))))
 '(org-document-title ((t (:weight bold :height 1.3))))
 '(org-level-1 ((t (:height 1.2))))
 '(org-level-2 ((t (:height 1.1))))
 '(org-warning ((t (:underline nil))))
 '(vertico-current ((t (:background "#264f78")))))
;;; Markdown Previews

(use-package move-text)
(move-text-default-bindings)
(global-set-key (kbd "C-M-p") 'move-text-up)
(global-set-key (kbd "C-M-n") 'move-text-down)
(global-set-key (kbd "C-l") "\C-a\C- \C-n\M-w\C-y")
(global-set-key (kbd "C-d") 'delete-char)

;;; emacs-w3m
 (setq browse-url-browser-function 'w3m-browse-url)
 (autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)
 ;; optional keyboard short-cut
 (global-set-key "\C-xm" 'browse-url-at-point)
