# Redmine TestCase Plugin - Installation Guide

## Prerequisites

- Redmine 5.x installed and running
- Ruby on Rails 5.2 or higher
- Database: MySQL, PostgreSQL, or SQLite
- Write access to Redmine's plugins directory
- Administrative access to Redmine

## Installation Steps

### Step 1: Download the Plugin

Clone or download the plugin into your Redmine plugins directory:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/jonasliu95/redmine_testcase.git
```

Or if you have a ZIP file:

```bash
cd /path/to/redmine/plugins
unzip redmine_testcase-0.1.0.zip
```

### Step 2: Verify Directory Structure

Ensure the plugin directory structure looks like this:

```
/path/to/redmine/plugins/redmine_testcase/
├── app/
├── assets/
├── config/
├── db/
├── lib/
├── test/
├── init.rb
├── README.md
└── ... other files
```

**Important:** The plugin directory must be named exactly `redmine_testcase`.

### Step 3: Run Database Migrations

Execute the plugin migrations to create the necessary database tables:

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

Expected output:
```
== CreateTestcases: migrating ================================================
-- create_table(:testcases)
   -> 0.0234s
-- add_index(:testcases, [:issue_id, :test_case_id], {:unique=>true})
   -> 0.0156s
-- add_index(:testcases, :issue_id)
   -> 0.0089s
-- add_index(:testcases, :position)
   -> 0.0067s
== CreateTestcases: migrated (0.0547s) =======================================
```

### Step 4: Restart Redmine

Restart your Redmine instance:

**For Passenger (Apache/Nginx):**
```bash
touch /path/to/redmine/tmp/restart.txt
```

**For WEBrick (development):**
```bash
# Stop the server (Ctrl+C) and start it again
bundle exec rails server -e production
```

**For Puma:**
```bash
systemctl restart redmine
# or
service redmine restart
```

**For Docker:**
```bash
docker-compose restart
```

### Step 5: Verify Installation

1. Log in to Redmine as an administrator
2. Navigate to **Administration → Plugins**
3. Verify "Redmine TestCase Plugin v0.1.0" appears in the list
4. The plugin should show as active/enabled

### Step 6: Configure the Plugin

1. In the Plugins list, find "Redmine TestCase Plugin"
2. Click **Configure**
3. Select the tracker you want to use for test case management
   - You can use an existing tracker (e.g., "Bug")
   - Or create a new tracker specifically for test cases:
     - Go to **Administration → Trackers**
     - Create a new tracker named "TestCase"
     - Return to plugin configuration
     - Select "TestCase" from the dropdown
4. Click **Save**

### Step 7: Configure Permissions

Set up role-based permissions:

1. Go to **Administration → Roles and permissions**
2. For each role, configure test case permissions:
   - **View test cases** - Allows read-only access
   - **Manage test cases** - Allows create, edit, delete access
3. Recommended setup:
   - Reporters/Developers: View test cases
   - QA/Managers: Manage test cases
   - Administrators: Full access (both permissions)

### Step 8: Enable Module in Project (Optional)

If your Redmine instance requires explicit module enabling:

1. Go to a project's **Settings → Modules**
2. Enable the "Test Cases" module
3. Save the project settings

### Step 9: Test the Installation

1. Create or open an issue with the configured tracker
2. Verify the "Test Cases" tab appears
3. Click "Add Test Case" and create a sample test case
4. Verify all functionality works:
   - Create, edit, delete
   - Status changes
   - Collapse/expand
   - CSV export
   - Print view

## Troubleshooting

### Plugin doesn't appear in Plugins list

**Solution:**
```bash
# Check if directory is correctly named
ls /path/to/redmine/plugins/
# Should show: redmine_testcase

# Check file permissions
chmod -R 755 /path/to/redmine/plugins/redmine_testcase

# Check Redmine logs
tail -f /path/to/redmine/log/production.log
```

### Migration errors

**Problem:** Migration fails with database errors

**Solution:**
```bash
# Rollback the migration
bundle exec rake redmine:plugins:migrate NAME=redmine_testcase VERSION=0 RAILS_ENV=production

# Try again
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

### Test Cases tab doesn't appear

**Checklist:**
- [ ] Is the tracker configured in plugin settings?
- [ ] Does the issue use the configured tracker?
- [ ] Does the current user have `view_test_cases` permission?
- [ ] Is the "Test Cases" module enabled for the project? (if applicable)

### JavaScript/CSS not loading

**Solution:**
```bash
# Clear asset cache
bundle exec rake tmp:cache:clear RAILS_ENV=production

# Precompile assets (if using asset pipeline)
bundle exec rake assets:precompile RAILS_ENV=production

# Restart server
touch tmp/restart.txt
```

### Permission denied errors

**Solution:**
```bash
# Fix file ownership (replace 'www-data' with your web server user)
chown -R www-data:www-data /path/to/redmine/plugins/redmine_testcase

# Fix permissions
chmod -R 755 /path/to/redmine/plugins/redmine_testcase
```

## Upgrade Instructions

### From 0.1.0 to Future Versions

1. **Backup your database** (important!)
   ```bash
   # For MySQL
   mysqldump -u username -p redmine_db > backup.sql

   # For PostgreSQL
   pg_dump -U username redmine_db > backup.sql
   ```

2. **Backup the plugin directory**
   ```bash
   cp -r /path/to/redmine/plugins/redmine_testcase /path/to/backup/
   ```

3. **Update plugin files**
   ```bash
   cd /path/to/redmine/plugins/redmine_testcase
   git pull origin main
   # or extract new version ZIP
   ```

4. **Run migrations**
   ```bash
   cd /path/to/redmine
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```

5. **Restart Redmine**
   ```bash
   touch tmp/restart.txt
   ```

6. **Clear cache**
   ```bash
   bundle exec rake tmp:cache:clear RAILS_ENV=production
   ```

7. **Verify upgrade**
   - Check Administration → Plugins for new version number
   - Test functionality in a test issue

## Uninstallation

### Complete Removal

**Warning:** This will delete all test case data permanently!

1. **Backup your data first**
   ```bash
   # Export all test cases to CSV before uninstalling
   ```

2. **Rollback database migrations**
   ```bash
   cd /path/to/redmine
   bundle exec rake redmine:plugins:migrate NAME=redmine_testcase VERSION=0 RAILS_ENV=production
   ```

3. **Remove plugin directory**
   ```bash
   rm -rf /path/to/redmine/plugins/redmine_testcase
   ```

4. **Restart Redmine**
   ```bash
   touch tmp/restart.txt
   ```

5. **Clear cache**
   ```bash
   bundle exec rake tmp:cache:clear RAILS_ENV=production
   ```

### Temporary Disable (without data loss)

To temporarily disable without removing data:

1. Rename the plugin directory:
   ```bash
   mv /path/to/redmine/plugins/redmine_testcase /path/to/redmine/plugins/redmine_testcase.disabled
   ```

2. Restart Redmine:
   ```bash
   touch tmp/restart.txt
   ```

To re-enable:
```bash
mv /path/to/redmine/plugins/redmine_testcase.disabled /path/to/redmine/plugins/redmine_testcase
touch tmp/restart.txt
```

## Getting Help

- **Documentation:** See README.md for usage guide
- **Issues:** https://github.com/jonasliu95/redmine_testcase/issues
- **Discussions:** https://github.com/jonasliu95/redmine_testcase/discussions
- **Redmine Community:** https://www.redmine.org/projects/redmine/boards

## System Requirements Summary

| Component | Requirement |
|-----------|-------------|
| Redmine | 5.x |
| Ruby | 2.5+ |
| Rails | 5.2+ |
| Database | MySQL 5.7+, PostgreSQL 10+, or SQLite 3 |
| Browser | Modern browser with JavaScript enabled |
| Disk Space | ~2 MB for plugin files |
| Memory | Negligible impact on Redmine memory usage |

## Performance Notes

- The plugin adds minimal overhead to Redmine
- Database indexes ensure fast queries even with hundreds of test cases
- JavaScript is loaded only on issue pages with test cases
- CSV export handles large datasets efficiently
