# Changelog

## master (unreleased)

### New features

- Use `after-focus-change-function` instead of the obsolete `focus-out-hook` for
  detecting frame focus loss.  Controlled by the new `super-save-when-focus-lost`
  option (enabled by default).
- Add a default predicate that checks `verify-visited-file-modtime` to avoid
  overwriting files modified outside Emacs.
- Add a default predicate that checks the parent directory exists before saving,
  to prevent errors when a file's directory has been removed.
- Wrap predicate evaluation in `condition-case` so a broken predicate logs a
  warning instead of disabling all auto-saving.
- Add support for saving `org-src` edit buffers (via `org-edit-src-save`) and
  `edit-indirect` buffers (via `edit-indirect--commit`).  Controlled by
  `super-save-handle-org-src` and `super-save-handle-edit-indirect` (both
  enabled by default).
- Use `window-buffer-change-functions' and `window-selection-change-functions' to
  detect buffer and window switches.  Controlled by the new
  `super-save-when-buffer-switched` option (enabled by default).  This catches all
  buffer switches regardless of how they happen, unlike `super-save-triggers`.

### Changes

- Require Emacs 27.1.
- Remove `focus-out-hook` from the default `super-save-hook-triggers`.

## 0.4.0 (2023-12-09)

### New features

- Make super-save checks customizable via `super-save-predicates`.
- Introduce defcustom `super-save-max-buffer-size` as a way to avoid auto-saving
  big files.
- Introduce defcustom `super-save-exclude` (a list of regular expressions) as a
  way to filter out certain buffer names from being auto-saved.
- [#43](https://github.com/bbatsov/crux/issues/43): Introduce `super-save-silent`
  to avoid printing messages in the `*Messages*` buffer or in the echo area.
- [#43](https://github.com/bbatsov/crux/issues/43): Introduce
  `super-save-delete-trailing-whitespace` which defaults to `nil` and accepts
  `t` to run `delete-trailing-whitespace` before saving the buffer. This
  variable accepts only the symbol `except-current-line` to delete trailing
  white spaces from all lines except the current one. This can be useful when we
  are in the middle of writing some thing and we add a space at the end, in this
  case, we more likely need the space to stay there instead of deleting it.
- [#44](https://github.com/bbatsov/crux/issues/44) &
  [#20](https://github.com/bbatsov/crux/issues/20): Introduce
  `super-save-all-buffers` to save all modified buffers instead of only the
  current one.

### Changes

- Require Emacs 25.1.

## 0.3.0 (2018-09-29)

### New features

- [#16](https://github.com/bbatsov/crux/issues/16): Make list of hook triggers
  customizable (see `super-save-hook-triggers`).
- [#18](https://github.com/bbatsov/crux/issues/18): Make it possible to disable
  super-save for remote files (see `super-save-remote-files`).

### Changes

- Make `super-save-triggers` a list of symbols (it used to be a list of strings).
- Trigger super-save on `next-buffer` and `previous-buffer`.

## 0.2.0 (2016-02-21)

### New features

- [#3](https://github.com/bbatsov/crux/issues/3): Turn super-save into a global
  minor-mode (`super-save-mode`).
- Add some functionality for auto-saving buffers when Emacs is idle (disabled by
  default).

## 0.1.0 (2016-02-11)

Initial release. Most of super-save was an extraction of a similar functionality I had originally developed for [Emacs Prelude](https://github.com/bbatsov/prelude).
