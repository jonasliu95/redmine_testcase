require File.expand_path('../../test_helper', __FILE__)

class TestcasesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules, :workflows,
           :attachments

  def setup
    @project = Project.find(1)
    @issue = Issue.find(1)
    @admin = User.find(1)
    @request.session[:user_id] = @admin.id
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => @issue.tracker_id.to_s}
    @project.enabled_module_names = (@project.enabled_module_names + ['test_cases']).uniq
  end

  def teardown
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
  end

  def test_index_with_attachment
    testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_ATTACHMENT',
      title: 'Test case with attachment',
      status: 'not_executed'
    )
    Attachment.create!(
      container: testcase,
      file: uploaded_test_file('testfile.txt', 'text/plain'),
      author_id: @admin.id
    )

    get :index, params: {issue_id: @issue.id}

    assert_response :success
  end
end
