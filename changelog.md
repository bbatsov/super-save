# Changelog

## master (unreleased)

### New features

* Make super-save checks customizable via `super-save-predicates`.
* Introduce defcustom `super-save-max-buffer-size` as a way to avoid auto-saving big files.
* Introduce defcustom `super-save-exclude` (a list of regular expression) as a way to filter out certain buffer names from being auto-saved.

## 0.3.0 (2018-09-29)

### New features

* [#16](https://github.com/bbatsov/crux/issues/16): Make this of hook triggers customizable (see `super-save-hook-triggers`).
* [#18](https://github.com/bbatsov/crux/issues/18): Make it possible to disable super-save for remote files (see `super-save-remote-files`).

### Changes

* Make `super-save-triggers` a list of symbols (it used to be a list of strings).
* Trigger super-save on `next-buffer` and `previous-buffer`.

## 0.2.0 (2016-02-21)

### New features

* [#3](https://github.com/bbatsov/crux/issues/3): Turn super-save into a global minor-mode (`super-save-mode`).
* Add some functionality for auto-saving buffers when Emacs is idle (disabled by default).

## 0.1.0 (2016-02-11)

Initial release. Most of super-save was an extraction of a similar functionality I had originally developed for [Emacs Prelude](https://github.com/bbatsov/prelude).
