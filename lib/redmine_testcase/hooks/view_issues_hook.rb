module RedmineTestcase
  module Hooks
    class ViewIssuesHook < Redmine::Hook::ViewListener
      # Add Test Cases section to issue view
      def view_issues_show_details_bottom(context={})
        issue = context[:issue]
        return '' unless issue

        # Check if this issue's tracker is configured for test cases
        return '' unless RedmineTestcase.enabled_for_issue?(issue)

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
