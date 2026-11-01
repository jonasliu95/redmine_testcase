# Changelog

## 0.3.0 (2026-11-01)

### Added

- Multiple test case trackers. `testcase_tracker_ids` accepts a list of tracker
  ids; the legacy single `testcase_tracker_id` setting keeps working until the
  new setting is saved.
- Structured test case steps (action, test data, expected/actual result and
  status) with add/remove rows in the form, numbered tables in the issue and
  print views, copy support, API output and CSV export.
- Inline images in preconditions, steps, expected/actual result, comments and
  structured step fields using Redmine attachments and wiki formatting
  (`!file.png!` for Textile, `![](file.png)` for CommonMark). Paste and
  drag-and-drop upload go through Redmine's attachments form.
- Drag-to-reorder for test cases and bulk status update for users with
  `manage_test_cases`.
- Test cases are copied when an issue is copied (status and actual result reset,
  attachments and structured steps included).
- Optional "Log test case changes as issue notes" setting, off by default.
- REST API for create, update and delete, plus reorder and bulk update, with JSON
  test cases including attachments and structured steps.
- Test coverage for permissions, multi-tracker settings, attachments, inline
  images, copying, reordering, bulk update, change history, structured steps and
  the API.

### Fixed

- `GET /issues/:id/testcases` crashed with `undefined method
  link_to_attachments` when a test case had attachments.
- Permissions were global: a user could read or change test cases in projects
  they could not see. Permissions are now scoped to the project and the
  `test_cases` project module, and the issue visibility is checked.
- Test cases are registered as an attachment object type, so
  `/attachments/testcases/:id/edit` and `/download` work.
- The issue page rendered the test case list twice with duplicate DOM ids and
  duplicate JS/CSS. It is rendered once now.
- The summary used one COUNT query per status; it now uses one grouped query and
  attachments/issues are preloaded.
- `index`/`show` did not support API authentication; `show` now redirects to the
  issue view for HTML.
- CSV export uses Redmine's CSV helpers (encoding and separator settings),
  translated headers and neutralises spreadsheet formula injection.
- Create/update validation failures return `422 Unprocessable Entity`.
- `manage_test_cases` requires a logged-in user.
- Removed stray development files, tracked `.DS_Store` files, the unused
  settings partial and the no-op initializer; added `.gitignore`.

### Changed

- Permissions now require the **Test cases** project module to be enabled per
  project. See the upgrade section in README.
- Requirements: Redmine 6.0 or newer (`requires_redmine`).
