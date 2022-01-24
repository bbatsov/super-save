[![License GPL 3][badge-license]][copying]
[![MELPA][melpa-badge]][melpa-package]
[![MELPA Stable][melpa-stable-badge]][melpa-stable-package]

# super-save

super-save auto-saves your buffers, when certain events happen - e.g. you switch between buffers,
an Emacs frame loses focus, etc. You can think of it as both something that augments and replaces
the standard `auto-save-mode`.

## Installation

Available on all major `package.el` community maintained repos -
[MELPA Stable][] and [MELPA][] repos.

MELPA Stable is recommended as it has the latest stable version.
MELPA has a development snapshot for users who don't mind breakage but
don't want to run from a git checkout.

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
originally developed for [Emacs
Prelude](https://github.com/bbatsov/prelude) and the package is bundled
with Prelude.

## Usage

Add the following to your Emacs config to enable
`super-save`:

```el
(super-save-mode +1)
```

If you want to enable the additional feature of auto-saving buffers
when Emacs is idle, add the following as well:

```el
(setq super-save-auto-save-when-idle t)
```

At this point you can probably switch off the built-in
`auto-save-mode` (unless you really care about its backups):

```el
(setq auto-save-default nil)
```

## Configuration

super-save will save files on command (e.g. `switch-to-buffer`) and
hook triggers (e.g. `focus-out-hook`).

Both of those are configurable via `super-save-triggers` and
`super-save-hook-triggers`. Here's a couple of examples:

```el
;; add integration with ace-window
(add-to-list 'super-save-triggers 'ace-window)

;; save on find-file
(add-to-list 'super-save-hook-triggers 'find-file-hook)
```

You can turn off `super-save` for remote files like this:

``` el
(setq super-save-remote-files nil)
```

Sometimes you might want to exclude specific files from super-save. You can
achieve this via `super-save-exclude`, for example:

``` el
(setq super-save-exclude '(".gpg"))
```

You can add predicate to `super-save-predicates`, this predicates must not take arguments and return nil, when current buffer shouldn't save. If predicate don't know needle of save file, then predicate must return t. Folowing example stop `super-save`, when current file in Markdown mode:
```elisp
(add-to-list 'super-save-predicates (lambda ()
                                        (not (eq major-mode 'markdown-mode))))
```

## License

Copyright © 2015-2020 Bozhidar Batsov and [contributors][].

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
