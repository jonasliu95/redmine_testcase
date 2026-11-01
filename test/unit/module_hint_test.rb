require File.expand_path('../../test_helper', __FILE__)

class ModuleHintTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :projects_trackers, :enabled_modules

  def teardown
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
  end

  def test_no_projects_listed_when_no_tracker_is_configured
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => []}

    assert_empty RedmineTestcase.projects_without_module
  end

  def test_lists_projects_that_allow_the_tracker_but_lack_the_module
    project = Project.find(1)
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => ['1']}
    project.enabled_module_names = project.enabled_module_names - ['test_cases']

    assert_includes RedmineTestcase.projects_without_module, project
  end

  def test_project_with_the_module_is_not_listed
    project = Project.find(1)
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => ['1']}
    project.enabled_module_names = project.enabled_module_names | ['test_cases']

    assert_not_includes RedmineTestcase.projects_without_module, project
  end

  def test_project_that_does_not_allow_the_tracker_is_not_listed
    project = Project.find(1)
    other_tracker = Tracker.where.not(id: project.trackers.map(&:id)).first || Tracker.create!(
      name: 'Hint tracker', default_status: IssueStatus.first
    )
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => [other_tracker.id.to_s]}
    project.enabled_module_names = project.enabled_module_names - ['test_cases']

    assert_not_includes RedmineTestcase.projects_without_module, project
  end
end
