require File.expand_path('../../test_helper', __FILE__)

class TestcaseAttachmentsTest < Redmine::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules, :workflows,
           :attachments

  def setup
    super
    @issue = Issue.find(1)
    @testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_ATTACHMENT',
      title: 'Test case with attachment',
      status: 'not_executed'
    )
    @attachment = Attachment.create!(
      container: @testcase,
      file: uploaded_test_file('testfile.txt', 'text/plain'),
      author_id: 1
    )
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => @issue.tracker_id.to_s}
    @issue.project.enabled_module_names = (@issue.project.enabled_module_names + ['test_cases']).uniq
  end

  def teardown
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
    super
  end

  def test_edit_all_attachments_of_a_test_case
    log_user('admin', 'admin')

    get "/attachments/testcases/#{@testcase.id}/edit"

    assert_response :success
  end

  def test_download_all_attachments_of_a_test_case
    log_user('admin', 'admin')

    get "/attachments/testcases/#{@testcase.id}/download"

    assert_response :success
  end
end
