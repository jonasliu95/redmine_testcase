require File.expand_path('../../test_helper', __FILE__)

class TestcaseApiTest < Redmine::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules, :workflows

  def setup
    super
    @issue = Issue.find(1)
    @testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_API',
      title: 'API test case',
      status: 'not_executed'
    )
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => @issue.tracker_id.to_s}
    Setting.rest_api_enabled = '1'
    @issue.project.enabled_module_names = (@issue.project.enabled_module_names + ['test_cases']).uniq
  end

  def teardown
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
    Setting.rest_api_enabled = '0'
    super
  end

  def test_index_json_with_basic_auth
    get "/issues/#{@issue.id}/testcases.json", headers: basic_auth_headers

    assert_response :success
    assert_equal 'application/json', response.media_type
    testcases = JSON.parse(response.body)
    assert_equal 1, testcases.size
    assert_equal 'TC_API', testcases.first['test_case_id']
  end

  def test_show_json_with_basic_auth
    get "/issues/#{@issue.id}/testcases/#{@testcase.id}.json", headers: basic_auth_headers

    assert_response :success
    assert_equal 'application/json', response.media_type
    testcase = JSON.parse(response.body)
    assert_equal 'TC_API', testcase['test_case_id']
  end

  def test_show_html_redirects_to_issue_test_case_tab
    log_user('admin', 'admin')

    get "/issues/#{@issue.id}/testcases/#{@testcase.id}"

    assert_redirected_to "/issues/#{@issue.id}?tab=testcases"
  end

  private

  def basic_auth_headers
    {
      'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'admin')
    }
  end
end
