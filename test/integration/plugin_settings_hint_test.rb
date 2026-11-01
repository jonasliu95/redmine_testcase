require File.expand_path('../../test_helper', __FILE__)

class PluginSettingsHintTest < Redmine::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules, :workflows

  def setup
    super
    @project = Project.find(1)
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => ['1']}
  end

  def teardown
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
    super
  end

  def test_settings_page_lists_projects_missing_the_module
    @project.enabled_module_names = @project.enabled_module_names - ['test_cases']
    log_user('admin', 'admin')

    get '/settings/plugin/redmine_testcase'

    assert_response :success
    assert_select 'div.testcase-module-warning' do
      assert_select "a[href=?]", "/projects/#{@project.identifier}/settings/modules", text: @project.name
    end
  end

  def test_settings_page_has_no_warning_when_every_project_has_the_module
    Project.active.each do |project|
      project.enabled_module_names = project.enabled_module_names | ['test_cases']
    end
    log_user('admin', 'admin')

    get '/settings/plugin/redmine_testcase'

    assert_response :success
    assert_select 'div.testcase-module-warning', false
  end
end
