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
      file: qa_png,
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

  def test_index_renders_textile_inline_attachment_image
    @testcase.update!(steps: '!qa.png!')
    log_user('admin', 'admin')

    with_text_formatting('textile') do
      get "/issues/#{@issue.id}/testcases"
    end

    assert_response :success
    assert_match(/<img[^>]+src="[^"]*qa\.png/, response.body)
  end

  def test_print_view_renders_textile_inline_attachment_image
    @testcase.update!(steps: '!qa.png!')
    log_user('admin', 'admin')

    with_text_formatting('textile') do
      get "/issues/#{@issue.id}/testcases/print_view"
    end

    assert_response :success
    assert_match(/<img[^>]+src="[^"]*qa\.png/, response.body)
  end

  def test_index_renders_common_mark_inline_attachment_image
    @testcase.update!(steps: '![](qa.png)')
    log_user('admin', 'admin')

    with_text_formatting('common_mark') do
      get "/issues/#{@issue.id}/testcases"
    end

    assert_response :success
    assert_match(/<img[^>]+src="[^"]*qa\.png/, response.body)
  end

  def test_index_renders_inline_image_in_structured_step
    @testcase.update!(steps: nil)
    TestcaseStep.create!(
      testcase: @testcase,
      action: '!qa.png!',
      test_data: 'qa.png',
      status: 'not_executed'
    )
    log_user('admin', 'admin')

    with_text_formatting('textile') do
      get "/issues/#{@issue.id}/testcases"
    end

    assert_response :success
    assert_match(/testcase-steps-table/, response.body)
    assert_match(/<img[^>]+src="[^"]*qa\.png/, response.body)
  end

  def test_print_view_renders_structured_steps
    @testcase.update!(steps: nil)
    TestcaseStep.create!(
      testcase: @testcase,
      action: 'Open the page',
      test_data: 'user@example.com',
      expected_result: 'Page loads',
      status: 'passed'
    )
    log_user('admin', 'admin')

    get "/issues/#{@issue.id}/testcases/print_view"

    assert_response :success
    assert_match(/testcase-steps-table/, response.body)
    assert_match(/Open the page/, response.body)
    assert_match(/user@example.com/, response.body)
    assert_match(/Page loads/, response.body)
  end

  private

  def with_text_formatting(format)
    original = Setting.text_formatting
    Setting.text_formatting = format
    yield
  ensure
    Setting.text_formatting = original
  end

  def qa_png
    Rack::Test::UploadedFile.new(
      File.expand_path('../fixtures/files/qa.png', __dir__),
      'image/png'
    )
  end
end
