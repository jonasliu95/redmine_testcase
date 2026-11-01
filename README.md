# Redmine TestCase Plugin

![Logo](img/testcase.jpg)

A Redmine plugin for managing manual test cases within issues.

## Features

- One or more test-case trackers per installation
- Test cases attached to issues, with status workflow and summary
- Pictures in every test case text field: paste or drag an image into the field
- Drag-to-reorder and bulk status update for users who can manage test cases
- Copy test cases when an issue is copied
- Optional issue notes for test case changes
- CSV export and print-friendly report
- JSON REST API with API-key or basic authentication

## Requirements

- Redmine 6.1.x or 7.0.x
- The `test_cases` project module enabled for every project that uses the plugin
- A role permission (`View test cases` or `Manage test cases`) in that project

## Installation

1. Copy the plugin directory to your Redmine `plugins` folder:
   ```bash
   cd /path/to/redmine/plugins
   cp -r /path/to/redmine_testcase .
   ```

2. Run the plugin migrations and precompile assets:
   ```bash
   cd /path/to/redmine
   bundle exec rake redmine:plugins:migrate NAME=redmine_testcase RAILS_ENV=production
   bundle exec rake assets:precompile RAILS_ENV=production
   ```

3. Restart Redmine:
   ```bash
   # For Passenger
   touch tmp/restart.txt

   # For other servers, restart accordingly
   ```

4. Log in as an administrator and verify the plugin under **Administration → Plugins**.

## Configuration

### Test case trackers

Go to **Administration → Plugins → Redmine TestCase Plugin → Configure** and
check every tracker that should offer test cases. Leave all trackers unchecked
to disable the feature.

The plugin still reads the legacy single `testcase_tracker_id` setting when the
new tracker list has never been saved, so existing installations keep working
after the upgrade.

### Project module and permissions

For each project that should use test cases:

1. Open **Project → Settings → Modules** and enable **Test cases**.
2. Open **Administration → Roles and permissions** (or the project's members
   page) and grant **View test cases** and/or **Manage test cases** to the
   roles that need them.

Permissions are project-scoped. A user who only has the permission in another
project cannot read or change test cases in this project.

## Usage

1. Open an issue whose tracker is selected in the plugin settings. The **Test
   Cases** section is shown below the issue details.
2. Use **Add Test Case** to create a test case. Each test case has a Test Case
   ID (e.g. `TC_UI_001`), title, preconditions, steps, expected result, actual result, status and comments.
3. Use **Export to CSV** to download all test cases, or **Print View** for a
   printer-friendly report.

### Pictures in test case fields

Preconditions, Test Steps, Expected Result, Actual Result and Comments accept
pictures:

- Paste a screenshot from the clipboard, or drag an image file onto the text
  box. Redmine uploads it and inserts a reference at the cursor; the picture is
  shown in that field when the test case is saved.
- You can also reference any attachment of the test case by hand:
  `!file.png!` (Textile) or `![](file.png)` (CommonMark).

Images are stored as normal attachments of the test case, so existing
attachment permissions, thumbnails and quotas apply. The print view renders the
images, and CSV keeps the raw markup.

### Reorder and bulk update

Users with **Manage test cases** can drag test cases by their header to change
the order, or select several test cases with the checkboxes, choose a status and
click **Apply**.

### Copying an issue

When an issue is copied and the target tracker is enabled for test cases, all
test cases are copied with:

- status reset to *Not Executed* and the actual result cleared
- the same position order
- their attachments

### Change history

Enable **Log test case changes as issue notes** in the plugin settings to add a
note to the parent issue whenever a test case is created, changed or deleted.
Notes are written as the current user. The setting is off by default because
issue notes send notifications to watchers.

Example note:

```
Test case TC_001 'Login': Status: Not Executed / Not Run → Passed
```

Only actual field changes are logged; saving without changes adds nothing.

## Test Case Statuses

- Not Executed / Not Run
- In Progress
- Passed
- Failed
- Blocked
- Skipped / Deferred
- Retest
- Reopened
- Closed / Completed

## REST API

Every endpoint is scoped to an issue. The `test_cases` project module must be
enabled for the issue's project and the user needs `view_test_cases` (read) or
`manage_test_cases` (write). Authenticate with an API key header or HTTP basic
auth; JSON requests skip session authentication.

| Method | Path | Permission | Response |
|--------|------|------------|----------|
| GET | `/issues/:issue_id/testcases.json` | view_test_cases | 200, array |
| GET | `/issues/:issue_id/testcases/:id.json` | view_test_cases | 200, test case |
| POST | `/issues/:issue_id/testcases.json` | manage_test_cases | 201, test case |
| PATCH/PUT | `/issues/:issue_id/testcases/:id.json` | manage_test_cases | 200, test case |
| DELETE | `/issues/:issue_id/testcases/:id.json` | manage_test_cases | 204 |
| PATCH | `/issues/:issue_id/testcases/reorder.json` | manage_test_cases | 200 |
| POST | `/issues/:issue_id/testcases/bulk_update.json` | manage_test_cases | 200 |

A test case object contains `id`, `issue_id`, `test_case_id`, `title`,
`preconditions`, `steps`, `expected_result`, `actual_result`, `status`,
`comments`, `position`, `created_on`, `updated_on`, `attachments` (`id`,
`filename`, `content_url`).

```bash
# List test cases
curl -H 'X-Redmine-API-Key: YOUR_KEY' \
  'http://redmine/issues/1/testcases.json'

# Show one test case
curl -u admin:YOUR_PASSWORD 'http://redmine/issues/1/testcases/4.json'

# Create (201 with the test case body)
curl -u admin:YOUR_PASSWORD -H 'Content-Type: application/json' \
  -X POST 'http://redmine/issues/1/testcases.json' \
  -d '{"testcase":{"test_case_id":"TC_001","title":"Login","status":"not_executed",
       "steps":"1. Open the page"}}'

# Update (200 with the test case body)
curl -u admin:YOUR_PASSWORD -H 'Content-Type: application/json' \
  -X PATCH 'http://redmine/issues/1/testcases/4.json' \
  -d '{"testcase":{"status":"passed"}}'

# Delete (204)
curl -u admin:YOUR_PASSWORD -X DELETE 'http://redmine/issues/1/testcases/4.json'

# Reorder (200). ordered_ids must belong to the issue.
curl -u admin:YOUR_PASSWORD -H 'Content-Type: application/json' \
  -X PATCH 'http://redmine/issues/1/testcases/reorder.json' \
  -d '{"ordered_ids":[4,2,3]}'

# Bulk status update (200, {"updated":2})
curl -u admin:YOUR_PASSWORD -H 'Content-Type: application/json' \
  -X POST 'http://redmine/issues/1/testcases/bulk_update.json' \
  -d '{"ids":[4,2],"status":"passed"}'
```

Validation failures return `422` with `{"errors": ["..."]}`; missing permission
returns `403`.

## Compatibility

Tested on Redmine 6.1.x (Rails 7.2) and Redmine 7.0.x (Rails 8.1), with SQLite
and PostgreSQL.

| Redmine | Rails | Status |
|---------|-------|--------|
| 6.1.x | 7.2 | Tested |
| 7.0.x | 8.1 | Tested |

| Locale | Status |
|--------|--------|
| en | Full support |
| lt | Full support |
| de | Older strings translated; new strings fall back to English |
| es | Older strings translated; new strings fall back to English |
| fr | Older strings translated; new strings fall back to English |
| it | Older strings translated; new strings fall back to English |
| ja | Older strings translated; new strings fall back to English |
| ru | Older strings translated; new strings fall back to English |

## Upgrading from 0.1.x

1. Copy the new plugin version over the old directory.
2. Enable the **Test cases** project module in every project that should use the
   plugin, then grant the role permissions there. Permissions were global in
   0.1.x and are project-scoped from 0.2.0 on.
3. The existing single-tracker setting is still honored. Open the plugin
   settings once to save the new multi-tracker checkbox list.
4. Run the migrations and precompile assets:
   ```bash
   bundle exec rake redmine:plugins:migrate NAME=redmine_testcase RAILS_ENV=production
   bundle exec rake assets:precompile RAILS_ENV=production
   ```
5. Restart Redmine.

## Uninstall

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate NAME=redmine_testcase VERSION=0 RAILS_ENV=production
rm -rf plugins/redmine_testcase
touch tmp/restart.txt
```

## Support

For issues and feature requests, please visit:
[GitHub Issues](https://github.com/jonasliu95/redmine_testcase/issues)

Improvements are widely accepted! If you have any suggestions, bug reports, or
translation updates, please open an issue on GitHub.

## License

This plugin is released under the MIT License.
