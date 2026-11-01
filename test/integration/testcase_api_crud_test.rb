require File.expand_path('../../test_helper', __FILE__)

class TestcaseApiCrudTest < Redmine::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules, :workflows, :attachments

  def setup
    super
    @issue = Issue.find(1)
    @admin = User.find(1)
    @view_only_user = User.find(2)
    @issue.project.enabled_module_names = (@issue.project.enabled_module_names + ['test_cases']).uniq
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => [@issue.tracker_id.to_s]}
    Setting.rest_api_enabled = '1'
    @testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_API_CRUD',
      title: 'API test case',
      status: 'not_executed',
      steps: 'Step one'
    )
  end

  def teardown
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
    Setting.rest_api_enabled = '0'
    super
  end

  def test_index_with_api_key
    get "/issues/#{@issue.id}/testcases.json", headers: api_key_headers(@admin)

    assert_response :success
    testcases = JSON.parse(response.body)
    assert_equal 1, testcases.size
    assert_equal 'TC_API_CRUD', testcases.first['test_case_id']
    assert_equal @issue.id, testcases.first['issue_id']
    assert testcases.first.key?('created_on')
    assert testcases.first.key?('updated_on')
    assert_equal [], testcases.first['attachments']
  end

  def test_show_with_basic_auth_includes_attachments
    Attachment.create!(
      container: @testcase,
      file: qa_png,
      author_id: @admin.id
    )

    get "/issues/#{@issue.id}/testcases/#{@testcase.id}.json", headers: basic_auth_headers

    assert_response :success
    testcase = JSON.parse(response.body)
    assert_equal 'TC_API_CRUD', testcase['test_case_id']
    assert_equal 1, testcase['attachments'].size
    assert_equal 'qa.png', testcase['attachments'].first['filename']
    assert_match(/qa\.png/, testcase['attachments'].first['content_url'])
  end

  def test_create_with_basic_auth
    assert_difference 'Testcase.count', 1 do
      post "/issues/#{@issue.id}/testcases.json",
           params: {
             testcase: {
               test_case_id: 'TC_API_NEW',
               title: 'Created through API',
               status: 'not_executed',
               steps: 'Open the page'
             }
           },
           headers: basic_auth_headers
    end

    assert_response :created
    testcase = JSON.parse(response.body)
    assert_equal 'TC_API_NEW', testcase['test_case_id']
    assert_equal 'Created through API', testcase['title']
    assert_equal 'Open the page', testcase['steps']
    assert_equal 'not_executed', testcase['status']
    assert_equal @issue.id, testcase['issue_id']
  end

  def test_create_with_invalid_data_returns_errors
    assert_no_difference 'Testcase.count' do
      post "/issues/#{@issue.id}/testcases.json",
           params: {testcase: {test_case_id: 'TC_API_BAD', title: ''}},
           headers: basic_auth_headers
    end

    assert_response :unprocessable_entity
    errors = JSON.parse(response.body)['errors']
    assert errors.any?
  end

  def test_update_with_api_key
    patch "/issues/#{@issue.id}/testcases/#{@testcase.id}.json",
          params: {testcase: {status: 'passed', actual_result: 'It worked'}},
          headers: api_key_headers(@admin)

    assert_response :success
    testcase = JSON.parse(response.body)
    assert_equal 'passed', testcase['status']
    assert_equal 'It worked', testcase['actual_result']
    assert_equal 'passed', @testcase.reload.status
  end

  def test_destroy_with_basic_auth
    assert_difference 'Testcase.count', -1 do
      delete "/issues/#{@issue.id}/testcases/#{@testcase.id}.json", headers: basic_auth_headers
    end

    assert_response :no_content
  end

  def test_create_without_manage_permission_is_forbidden
    assert_no_difference 'Testcase.count' do
      post "/issues/#{@issue.id}/testcases.json",
           params: {testcase: {test_case_id: 'TC_API_DENIED', title: 'Denied'}},
           headers: api_key_headers(@view_only_user)
    end

    assert_response :forbidden
  end

  private

  def basic_auth_headers
    {
      'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'admin')
    }
  end

  def api_key_headers(user)
    {'X-Redmine-API-Key' => user.api_key}
  end

  def qa_png
    Rack::Test::UploadedFile.new(
      File.expand_path('../fixtures/files/qa.png', __dir__),
      'image/png'
    )
  end
end
