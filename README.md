[![License GPL 3][badge-license]][copying]
[![MELPA][melpa-badge]][melpa-package]
[![MELPA Stable][melpa-stable-badge]][melpa-stable-package]
[![Build Status](https://github.com/bbatsov/super-save/workflows/CI/badge.svg)](https://github.com/bbatsov/super-save/actions?query=workflow%3ACI)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-red?logo=GitHub)](https://github.com/sponsors/bbatsov)

# super-save

`super-save` auto-saves your buffers when certain events happen - e.g. you switch
between buffers, an Emacs frame loses focus, etc. You can think of it as both
something that augments and replaces the standard `auto-save-mode`.

**This package requires Emacs 27.1+.**

## Rationale

I created `super-save` because I wanted Emacs to save files the way IntelliJ
IDEA and other modern editors do — automatically, when you switch buffers or
leave the editor. No manual `C-x C-s`, no thinking about it. I first wrote
about this idea [back in
2012](https://batsov.com/articles/2012/03/08/emacs-tip-number-5-save-buffers-automatically-on-buffer-or-window-switch/),
and `super-save` grew out of the buffer auto-saving functionality I had built
for [Emacs Prelude](https://github.com/bbatsov/prelude).

Emacs has a built-in `auto-save-mode`, but it solves a different problem — it's
a crash-recovery mechanism that periodically writes buffer contents to temporary
`#file#` backup files. That's useful as a safety net, but it's not the same as
actually saving your files. You still have to remember to hit save, and you end
up with `#backup#` files scattered around your filesystem.

`super-save` takes a simpler approach: it just saves your files (for real) when
natural editing events happen — switching buffers, switching windows, losing
focus, or going idle. No backup files, no recovery dance, no extra complexity.
Your files are always saved, and you never have to think about it.

## Installation

Available on all major `package.el` community maintained repos - [MELPA
Stable][] and [MELPA][] repos.

MELPA Stable is recommended as it has the latest stable version. MELPA has a
development snapshot for users who don't mind breakage but don't want to run
from a git checkout.

You can install `super-save` using the following command:

<kbd>M-x package-install [RET] super-save [RET]</kbd>

or if you'd rather keep it in your dotfiles:

```el
(unless (package-installed-p 'super-save)
  (package-refresh-contents)
  (package-install 'super-save))
```

If the installation doesn't work try refreshing the package list:

<kbd>M-x package-refresh-contents</kbd>

### use-package

If you're into `use-package` you can use the following snippet:

```el
(use-package super-save
  :ensure t
  :config
  (super-save-mode +1))
```

### Emacs Prelude

super-save started its life as the extraction of a similar functionality I had
originally developed for [Emacs Prelude](https://github.com/bbatsov/prelude) and
the package is bundled with Prelude.

## Usage

Add the following to your Emacs config to enable
`super-save`:

```el
(super-save-mode +1)
```

If you want to enable the additional feature of auto-saving buffers when Emacs
is idle, add the following as well:

```el
(setq super-save-auto-save-when-idle t)
```

By default the idle delay is 5 seconds. You can change it via
`super-save-idle-duration`:

```el
(setq super-save-idle-duration 10)
```

`super-save-auto-save-when-idle` can be set buffer-locally, so you can disable
idle saving for specific modes (e.g., modes where `before-save-hook` runs
expensive formatters):

```el
(add-hook 'go-mode-hook (lambda () (setq-local super-save-auto-save-when-idle nil)))
```

At this point you can probably switch off the built-in `auto-save-mode` (unless
you really care about its backups):

```el
(setq auto-save-default nil)
```

## Configuration

super-save will save files when certain events happen:

- **Frame focus loss** — controlled by `super-save-when-focus-lost` (enabled by default)
- **Buffer/window switches** — controlled by `super-save-when-buffer-switched` (enabled by default)
- **Command triggers** — configurable via `super-save-triggers` (empty by default, since the window-system hooks above already catch all buffer switches)
- **Hook triggers** — configurable via `super-save-hook-triggers` (empty by default)

```el
;; disable saving on focus loss
(setq super-save-when-focus-lost nil)

;; disable saving on buffer/window switch
(setq super-save-when-buffer-switched nil)

;; add a command trigger (useful for commands that don't involve a buffer switch)
(add-to-list 'super-save-triggers 'ace-window)

;; add a hook trigger
(add-to-list 'super-save-hook-triggers 'find-file-hook)
```

You can turn off `super-save` for remote files like this:

```el
(setq super-save-remote-files nil)
```

If you have very large files that are slow to save, you can set a size limit
(in characters) via `super-save-max-buffer-size`:

```el
(setq super-save-max-buffer-size 5000000)
```

Sometimes you might want to exclude specific files from super-save. You can
achieve this via `super-save-exclude`, for example:

```el
(setq super-save-exclude '(".gpg"))
```

The default predicates check that the buffer is visiting a file, is modified,
is writable, hasn't been modified externally, and that its parent directory
still exists. You can add your own predicates to `super-save-predicates`.
These predicates must not take arguments and return nil when the current buffer
shouldn't be saved. If a predicate doesn't know whether the buffer needs to be
saved, it must return t. The following example stops `super-save` when the
current buffer is in Markdown mode:

```el
(add-to-list 'super-save-predicates (lambda ()
                                        (not (eq major-mode 'markdown-mode))))
```

When saving a file automatically, Emacs will display a message in the
`*Messages*` buffer and in the echo area. If you want to suppress these
messages, you can set `super-save-silent` to `t`.

```el
;; Save silently
(setq super-save-silent t)
```

The `super-save-delete-trailing-whitespace` variable can be used to enable
deleting trailing white spaces before saving (via Emacs'
`delete-trailing-whitespace`).

```el
;; Enable deleting trailing white spaces before saving
(setq super-save-delete-trailing-whitespace t)

;; Enable deleting trailing white spaces before saving (except for the current line)
(setq super-save-delete-trailing-whitespace 'except-current-line)
```

### org-src and edit-indirect buffers

`super-save` can save `org-src` edit buffers (using `org-edit-src-save`) and
`edit-indirect` buffers (using `edit-indirect--commit`). Both are enabled by
default and can be disabled:

```el
(setq super-save-handle-org-src nil)
(setq super-save-handle-edit-indirect nil)
```

### Saving all buffers

By default, `super-save` will automatically save only the current buffer, if you
want to save all open buffers you can set `super-save-all-buffers` to `t`.

Setting this to `t` can be interesting when you make indirect buffer edits, like
when editing `grep` results with `occur-mode` and `occur-edit-mode`, or when
running a project-wide search and replace with `project-query-replace-regexp`
and so on.  In these cases, we can indirectly edit several buffers without
actually visiting or switching to these buffers.  Hence, this option allows you to
automatically save these buffers, even when they aren't visible in any window.

## Alternatives and Overlap

Emacs 26.1 introduced `auto-save-visited-mode`, which saves file-visiting
buffers to their actual files after a configurable idle delay
(`auto-save-visited-interval`, default 5 seconds). This overlaps directly with
`super-save`'s `super-save-auto-save-when-idle` feature, so there's no need to
enable both. If idle saving is all you need, the built-in mode might be enough.

Where `super-save` goes further is event-driven saving — it saves immediately
when you switch buffers, switch windows, or leave Emacs, rather than waiting for
an idle timeout. It also provides a predicate system for fine-grained control
(max buffer size, exclude patterns, remote file handling, external modification
checks), silent saving, trailing whitespace cleanup, and special handling for
`org-src` and `edit-indirect` buffers.

A common setup is to use `super-save` for event-driven saves and
`auto-save-visited-mode` for idle saves:

```el
(super-save-mode +1)
(auto-save-visited-mode +1)
```

## License

Copyright © 2015-2026 Bozhidar Batsov and [contributors][].

Distributed under the GNU General Public License; type <kbd>C-h C-c</kbd> to view it.

[badge-license]: https://img.shields.io/badge/license-GPL_3-green.svg
[melpa-badge]: http://melpa.org/packages/super-save-badge.svg
[melpa-stable-badge]: http://stable.melpa.org/packages/super-save-badge.svg
[melpa-package]: http://melpa.org/#/super-save
[melpa-stable-package]: http://stable.melpa.org/#/super-save
[COPYING]: http://www.gnu.org/copyleft/gpl.html
[contributors]: https://github.com/bbatsov/super-save/contributors
[melpa]: http://melpa.org
[melpa stable]: http://stable.melpa.org
