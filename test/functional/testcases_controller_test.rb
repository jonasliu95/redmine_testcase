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

  def test_export_csv_uses_redmine_csv_helpers_and_sanitizes_formulas
    Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_CSV',
      title: '=HYPERLINK("http://example.com")',
      status: 'not_executed',
      steps: '+cmd',
      comments: '@SUM(A1:A2)'
    )

    get :export_csv, params: {issue_id: @issue.id, encoding: 'UTF-8', field_separator: ';'}

    assert_response :success
    body = response.body.dup.force_encoding('UTF-8').sub("\xEF\xBB\xBF", '')
    rows = CSV.parse(body, col_sep: ';')
    assert_equal ['Issue', 'Subject', 'Test Case ID', 'Title', 'Preconditions', 'Test Steps',
                  'Expected Result', 'Actual Result', 'Status', 'Comments', 'Last Updated'],
                 rows.first
    row = rows.last
    assert_equal %q{'=HYPERLINK("http://example.com")}, row[3]
    assert_equal "'+cmd", row[5]
    assert_equal "'@SUM(A1:A2)", row[9]
  end

  def test_export_csv_keeps_raw_inline_image_markup
    testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_CSV_IMAGE',
      title: 'Image test case',
      status: 'not_executed',
      steps: '!qa.png!'
    )
    Attachment.create!(
      container: testcase,
      file: qa_png,
      author_id: @admin.id
    )

    get :export_csv, params: {issue_id: @issue.id, encoding: 'UTF-8'}

    assert_response :success
    body = response.body.dup.force_encoding('UTF-8').sub("\xEF\xBB\xBF", '')
    assert_includes body, '!qa.png!'
  end

  def test_new_form_has_wiki_toolbars_and_attachment_drop_target
    get :new, params: {issue_id: @issue.id}

    assert_response :success
    %w[testcase_preconditions testcase_steps testcase_expected_result testcase_actual_result testcase_comments].each do |field_id|
      assert_match(/id="#{field_id}"/, response.body)
      assert_match(/new jsToolBar\(document.getElementById\('#{field_id}'\)\)/, response.body)
    end
    assert_match(/attachments\[dummy\]\[file\]/, response.body)
    assert_match(/class="[^"]*filedrop/, response.body)
  end

  def test_edit_form_has_wiki_toolbars_and_attachment_drop_target
    testcase = Testcase.create!(valid_testcase_attributes.merge(issue: @issue))

    get :edit, params: {issue_id: @issue.id, id: testcase.id}

    assert_response :success
    %w[testcase_preconditions testcase_steps testcase_expected_result testcase_actual_result testcase_comments].each do |field_id|
      assert_match(/new jsToolBar\(document.getElementById\('#{field_id}'\)\)/, response.body)
    end
    assert_match(/attachments\[dummy\]\[file\]/, response.body)
    assert_match(/class="[^"]*filedrop/, response.body)
  end

  def test_index_preloads_attachments
    testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_PRELOAD',
      title: 'Test case with attachment',
      status: 'not_executed'
    )
    Attachment.create!(
      container: testcase,
      file: uploaded_test_file('testfile.txt', 'text/plain'),
      author_id: @admin.id
    )

    get :index, params: {issue_id: @issue.id}

    testcases = @controller.instance_variable_get(:@testcases)
    assert testcases.first.association(:attachments).loaded?
  end

  def test_create_with_invalid_test_case_returns_unprocessable_entity
    post :create, params: {
      issue_id: @issue.id,
      testcase: {test_case_id: 'TC_INVALID', title: '', status: 'not_executed'}
    }

    assert_response :unprocessable_entity
  end

  def test_update_with_invalid_test_case_returns_unprocessable_entity
    testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_INVALID',
      title: 'Valid title',
      status: 'not_executed'
    )

    patch :update, params: {
      issue_id: @issue.id,
      id: testcase.id,
      testcase: {title: ''}
    }

    assert_response :unprocessable_entity
  end

  def test_user_with_permission_in_project_can_view_test_cases
    Role.find(1).add_permission!(:view_test_cases)
    @request.session[:user_id] = 2

    get :index, params: {issue_id: @issue.id}

    assert_response :success
  end

  def test_view_only_user_cannot_create_test_case
    grant_view_only_permission
    testcase = valid_testcase_attributes

    assert_no_difference 'Testcase.count' do
      post :create, params: {issue_id: @issue.id, testcase: testcase}
    end

    assert_response :forbidden
  end

  def test_legacy_single_tracker_setting_allows_issue
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => @issue.tracker_id.to_s}

    get :index, params: {issue_id: @issue.id}

    assert_response :success
  end

  def test_multiple_tracker_settings_allow_each_tracker
    issue_with_tracker_2 = Issue.find(2)
    Setting.plugin_redmine_testcase = {
      'testcase_tracker_ids' => [@issue.tracker_id.to_s, issue_with_tracker_2.tracker_id.to_s]
    }

    get :index, params: {issue_id: @issue.id}
    assert_response :success

    get :index, params: {issue_id: issue_with_tracker_2.id}
    assert_response :success
  end

  def test_issue_on_non_selected_tracker_is_forbidden
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => [@issue.tracker_id.to_s]}
    issue_with_other_tracker = Issue.find(2)

    get :index, params: {issue_id: issue_with_other_tracker.id}

    assert_response :forbidden
  end

  def test_reorder_updates_positions_in_the_given_order
    first = Testcase.create!(valid_testcase_attributes.merge(issue: @issue, test_case_id: 'TC_R1', position: 1))
    second = Testcase.create!(valid_testcase_attributes.merge(issue: @issue, test_case_id: 'TC_R2', position: 2))
    third = Testcase.create!(valid_testcase_attributes.merge(issue: @issue, test_case_id: 'TC_R3', position: 3))

    patch :reorder, params: {issue_id: @issue.id, ordered_ids: [third.id, first.id, second.id]}

    assert_response :success
    assert_equal [third.id, first.id, second.id], @issue.testcases.reorder(:position).pluck(:id)
    assert_equal [1, 2, 3], @issue.testcases.reorder(:position).pluck(:position)
  end

  def test_reorder_rejects_test_cases_from_another_issue
    testcase = Testcase.create!(valid_testcase_attributes.merge(issue: @issue, test_case_id: 'TC_R4', position: 1))
    other_issue = Issue.find(3)
    other_testcase = Testcase.create!(
      valid_testcase_attributes.merge(issue: other_issue, test_case_id: 'TC_R5', position: 1)
    )

    patch :reorder, params: {issue_id: @issue.id, ordered_ids: [testcase.id, other_testcase.id]}

    assert_response :unprocessable_entity
    assert_equal 1, testcase.reload.position
    assert_equal 1, other_testcase.reload.position
  end

  def test_view_only_user_cannot_reorder
    first = Testcase.create!(valid_testcase_attributes.merge(issue: @issue, test_case_id: 'TC_R6', position: 1))
    second = Testcase.create!(valid_testcase_attributes.merge(issue: @issue, test_case_id: 'TC_R7', position: 2))
    grant_view_only_permission

    patch :reorder, params: {issue_id: @issue.id, ordered_ids: [second.id, first.id]}

    assert_response :forbidden
    assert_equal [first.id, second.id], @issue.testcases.reorder(:position).pluck(:id)
  end

  def test_view_only_user_cannot_update_test_case
    grant_view_only_permission
    testcase = Testcase.create!(valid_testcase_attributes.merge(issue: @issue, title: 'Original title'))

    patch :update, params: {
      issue_id: @issue.id,
      id: testcase.id,
      testcase: {title: 'Changed title'}
    }

    assert_response :forbidden
    assert_equal 'Original title', testcase.reload.title
  end

  def test_view_only_user_cannot_delete_test_case
    grant_view_only_permission
    testcase = Testcase.create!(valid_testcase_attributes.merge(issue: @issue))

    assert_no_difference 'Testcase.count' do
      delete :destroy, params: {issue_id: @issue.id, id: testcase.id}
    end

    assert_response :forbidden
    assert Testcase.exists?(testcase.id)
  end

  def test_user_with_permission_in_another_project_cannot_view_private_issue_test_cases
    Role.find(1).add_permission!(:view_test_cases, :manage_test_cases)
    private_issue = create_private_project_issue
    @request.session[:user_id] = 2

    get :index, params: {issue_id: private_issue.id}

    assert_response :not_found
  end

  def test_user_with_permission_in_another_project_cannot_manage_private_issue_test_cases
    Role.find(1).add_permission!(:view_test_cases, :manage_test_cases)
    private_issue = create_private_project_issue
    @request.session[:user_id] = 2

    get :new, params: {issue_id: private_issue.id}

    assert_response :not_found
  end

  private

  def grant_view_only_permission
    Role.find(1).add_permission!(:view_test_cases)
    @request.session[:user_id] = 2
  end

  def valid_testcase_attributes
    {test_case_id: 'TC_PERM', title: 'Permission test case', status: 'not_executed'}
  end

  def qa_png
    Rack::Test::UploadedFile.new(
      File.expand_path('../fixtures/files/qa.png', __dir__),
      'image/png'
    )
  end

  def create_private_project_issue
    project = Project.create!(
      name: 'Private project',
      identifier: 'private-project',
      is_public: false
    )
    project.enabled_module_names = ['issue_tracking', 'test_cases']
    Issue.create!(
      project: project,
      tracker: @issue.tracker,
      subject: 'Private issue',
      author: @admin,
      status: IssueStatus.find(1),
      priority: IssuePriority.find(5)
    )
  end
end
