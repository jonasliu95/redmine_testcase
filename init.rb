require 'redmine'

require_relative 'lib/redmine_testcase/patches/issue_patch'

Redmine::Plugin.register :redmine_testcase do
  name 'Redmine TestCase Plugin'
  author 'Jonas Liubinas (liubinas.jonas@gmail.com)'
  description 'A plugin for managing manual test cases within Redmine issues'
  version '0.3.0'
  url 'https://github.com/jonasliu95/redmine_testcase'
  author_url 'https://github.com/jonasliu95'
  requires_redmine version_or_higher: '6.0.0'

  # Plugin settings (global, not project-specific)
  settings default: {
    'testcase_tracker_id' => nil,
    'testcase_tracker_ids' => [],
    'log_changes_to_issue' => false
  }, partial: 'settings/testcase_settings'

  # Define project-scoped permissions under the test_cases project module
  project_module :test_cases do
    permission :view_test_cases, {
      testcases: [:index, :show, :export_csv, :print_view]
    }, public: false

    permission :manage_test_cases, {
      testcases: [:index, :show, :new, :create, :edit, :update, :destroy, :export_csv, :print_view, :reorder, :bulk_update]
    }, public: false, require: :loggedin
  end
end

# Load hooks
require_relative 'lib/redmine_testcase/hooks/view_issues_hook'

# Register Testcase as an attachable object type so the core attachments routes
# (/attachments/testcases/:id/edit and /download) and attachments/_form work.
# Plugin initializers run inside a to_prepare callback, after core plugins have
# mixed Redmine::Acts::Attachable into ApplicationRecord.
Redmine::Plugin.find(:redmine_testcase).attachment_object_type(Testcase)

issue_patch = proc do
  require_dependency 'issue'

  unless Issue.included_modules.include?(RedmineTestcase::Patches::IssuePatch)
    Issue.include RedmineTestcase::Patches::IssuePatch
  end

  unless Issue.ancestors.include?(RedmineTestcase::Patches::IssueCopyPatch)
    Issue.prepend RedmineTestcase::Patches::IssueCopyPatch
  end
end

# Apply immediately so the association is present even before the first reload
issue_patch.call

# Re-apply on each reload in development mode
if defined?(ActiveSupport::Reloader)
  ActiveSupport::Reloader.to_prepare(&issue_patch)
else
  Rails.configuration.to_prepare(&issue_patch)
end

helper_patch = proc do
  require_dependency 'issues_controller'

  unless defined?(TestcasesHelper)
    require File.expand_path('app/helpers/testcases_helper', __dir__)
  end

  IssuesController.helper :testcases unless IssuesController._helpers.include?(TestcasesHelper)
end

helper_patch.call

if defined?(ActiveSupport::Reloader)
  ActiveSupport::Reloader.to_prepare(&helper_patch)
else
  Rails.configuration.to_prepare(&helper_patch)
end
