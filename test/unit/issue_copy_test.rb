require File.expand_path('../../test_helper', __FILE__)

class IssueCopyTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules, :workflows, :attachments

  def setup
    @issue = Issue.find(1)
    @project = @issue.project
    @project.enabled_module_names = (@project.enabled_module_names + ['test_cases']).uniq
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => [@issue.tracker_id.to_s]}
    @testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_COPY',
      title: 'Copy me',
      status: 'passed',
      actual_result: 'Old actual result',
      position: 3
    )
    Attachment.create!(
      container: @testcase,
      file: qa_png,
      author_id: User.find(1).id
    )
    TestcaseStep.create!(
      testcase: @testcase,
      action: 'Open the page',
      test_data: 'user@example.com',
      expected_result: 'Page loads',
      status: 'passed',
      actual_result: 'It loaded'
    )
  end

  def teardown
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
  end

  def test_copying_an_issue_copies_its_test_cases_and_attachments
    copy = build_copy

    assert_difference 'Testcase.count', 1 do
      copy.save!
    end

    copied = copy.testcases.first
    assert_equal 'TC_COPY', copied.test_case_id
    assert_equal 'Copy me', copied.title
    assert_equal 'not_executed', copied.status
    assert_nil copied.actual_result
    assert_equal 3, copied.position
    assert_equal ['qa.png'], copied.attachments.map(&:filename)

    copied_step = copied.testcase_steps.first
    assert_equal 'Open the page', copied_step.action
    assert_equal 'user@example.com', copied_step.test_data
    assert_equal 'not_executed', copied_step.status
    assert_nil copied_step.actual_result
  end

  def test_copying_an_issue_without_enabled_tracker_does_not_copy_test_cases
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => []}
    copy = build_copy

    assert_no_difference 'Testcase.count' do
      copy.save!
    end
  end

  private

  def build_copy
    copy = Issue.new.copy_from(@issue)
    copy.project = @project
    copy.author = User.find(1)
    copy.subject = 'Copied issue'
    copy
  end

  def qa_png
    Rack::Test::UploadedFile.new(
      File.expand_path('../fixtures/files/qa.png', __dir__),
      'image/png'
    )
  end
end
