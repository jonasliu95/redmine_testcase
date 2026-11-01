module RedmineTestcase
  module Hooks
    class ViewIssuesHook < Redmine::Hook::ViewListener
      # Add Test Cases tab to issue view
      def view_issues_show_details_bottom(context={})
        issue = context[:issue]
        return '' unless issue

        # Check if this issue's tracker is configured for test cases
        testcase_tracker_id = Setting.plugin_redmine_testcase['testcase_tracker_id']
        return '' if testcase_tracker_id.blank?
        return '' unless issue.tracker_id.to_s == testcase_tracker_id.to_s

        # Check project-scoped permissions
        return '' unless User.current.allowed_to?(:view_test_cases, issue.project)

        # Render test cases section
        context[:controller].send(:render_to_string, {
          partial: 'testcases/issue_test_cases',
          locals: { issue: issue }
        })
      end
    end
  end
end
