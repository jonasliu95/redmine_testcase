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

        # Check global permissions
        return '' unless User.current.allowed_to_globally?(:view_test_cases)

        # Render test cases section
        context[:controller].send(:render_to_string, {
          partial: 'testcases/issue_test_cases',
          locals: { issue: issue }
        })
      end

      # Add tab link to issue tabs
      render_on :view_issues_show_description_bottom,
                partial: 'testcases/issue_tab_link'
    end
  end
end
