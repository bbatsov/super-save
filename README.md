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

Add the following to your Emacs config to enable
`super-save` for Clojure source buffers:

```el
(super-save-initialize)
```

## License

Copyright © 2015 Bozhidar Batsov and [contributors][].

Distributed under the GNU General Public License; type <kbd>C-h C-c</kbd> to view it.

[badge-license]: https://img.shields.io/badge/license-GPL_3-green.svg
[melpa-badge]: http://melpa.org/packages/super-save-badge.svg
[melpa-stable-badge]: http://stable.melpa.org/packages/super-save-badge.svg
[melpa-package]: http://melpa.org/#/super-save
[melpa-stable-package]: http://stable.melpa.org/#/super-save
[COPYING]: http://www.gnu.org/copyleft/gpl.html
[contributors]: https://github.com/clojure-emacs/super-save/contributors
[melpa]: http://melpa.org
[melpa stable]: http://stable.melpa.org
