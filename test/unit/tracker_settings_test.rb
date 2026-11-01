require File.expand_path('../../test_helper', __FILE__)

class TrackerSettingsTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules

  def setup
    @issue_with_tracker_1 = Issue.find(1)
    @issue_with_tracker_2 = Issue.find(2)
  end

  def teardown
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
  end

  def test_legacy_single_tracker_setting_is_used_when_new_key_is_absent
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => '1'}

    assert_equal ['1'], RedmineTestcase.tracker_ids
    assert RedmineTestcase.tracker_configured?
    assert RedmineTestcase.enabled_for_issue?(@issue_with_tracker_1)
    assert_not RedmineTestcase.enabled_for_issue?(@issue_with_tracker_2)
  end

  def test_multiple_trackers_are_enabled
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => %w[1 2]}

    assert_equal %w[1 2], RedmineTestcase.tracker_ids
    assert RedmineTestcase.tracker_configured?
    assert RedmineTestcase.enabled_for_issue?(@issue_with_tracker_1)
    assert RedmineTestcase.enabled_for_issue?(@issue_with_tracker_2)
  end

  def test_present_but_empty_key_disables_legacy_setting
    Setting.plugin_redmine_testcase = {
      'testcase_tracker_id' => '1',
      'testcase_tracker_ids' => []
    }

    assert_equal [], RedmineTestcase.tracker_ids
    assert_not RedmineTestcase.tracker_configured?
    assert_not RedmineTestcase.enabled_for_issue?(@issue_with_tracker_1)
  end

  def test_saved_empty_value_disables_all_trackers
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => ['']}

    assert_equal [], RedmineTestcase.tracker_ids
    assert_not RedmineTestcase.tracker_configured?
  end

  def test_blank_values_are_ignored
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => ['', ' 1 ', '', '2']}

    assert_equal %w[1 2], RedmineTestcase.tracker_ids
  end

  def test_trackers_returns_only_selected_trackers_in_order
    Setting.plugin_redmine_testcase = {'testcase_tracker_ids' => %w[2 1]}

    assert_equal [Tracker.find(1), Tracker.find(2)], RedmineTestcase.trackers.to_a
  end
end
