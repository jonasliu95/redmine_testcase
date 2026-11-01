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

  def test_issue_page_hides_list_for_tracker_not_selected
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => [@issue.tracker_id.to_s]}
    log_user('admin', 'admin')

    get "/issues/2"

    assert_response :success
    assert_no_match(/id="testcase-status-filter"/, response.body)
  end

  def test_issue_page_renders_list_for_each_selected_tracker
    issue_with_other_tracker = Issue.find(2)
    Testcase.create!(
      issue: issue_with_other_tracker,
      test_case_id: 'TC_RENDER_2',
      title: 'Rendered on tracker 2',
      status: 'not_executed'
    )
    Setting.plugin_redmine_testcase = {
      'testcase_tracker_ids' => [@issue.tracker_id.to_s, issue_with_other_tracker.tracker_id.to_s]
    }
    log_user('admin', 'admin')

    get "/issues/#{issue_with_other_tracker.id}"

    assert_response :success
    assert_equal 1, response.body.scan('id="testcase-status-filter"').size
  end
end
