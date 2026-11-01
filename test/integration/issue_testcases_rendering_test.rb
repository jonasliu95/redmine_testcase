require File.expand_path('../../test_helper', __FILE__)

class IssueTestcasesRenderingTest < Redmine::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules, :workflows

  def setup
    super
    @issue = Issue.find(1)
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => @issue.tracker_id.to_s}
    @issue.project.enabled_module_names = (@issue.project.enabled_module_names + ['test_cases']).uniq
    Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_RENDER',
      title: 'Rendered test case',
      status: 'not_executed'
    )
  end

  def teardown
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
    super
  end

  def test_issue_page_renders_test_case_list_once
    log_user('admin', 'admin')

    get "/issues/#{@issue.id}"

    assert_response :success
    assert_equal 1, response.body.scan('id="testcase-status-filter"').size
    assert_equal 1, response.body.scan('id="collapse-all-btn"').size
    assert_equal 1, response.body.scan(/testcases-[0-9a-f]+\.js/).size
  end
end
