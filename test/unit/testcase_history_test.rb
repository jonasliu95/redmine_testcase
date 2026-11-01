require File.expand_path('../../test_helper', __FILE__)

class TestcaseHistoryTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules, :workflows, :journals

  def setup
    @issue = Issue.find(1)
    @user = User.find(2)
    User.current = @user
  end

  def teardown
    User.current = nil
    Setting.plugin_redmine_testcase = {'testcase_tracker_id' => nil}
  end

  def test_create_adds_an_issue_note_when_setting_is_on
    enable_history

    assert_difference 'Journal.where(journalized_id: @issue.id, journalized_type: "Issue").count', 1 do
      Testcase.create!(
        issue: @issue,
        test_case_id: 'TC_H1',
        title: 'History test',
        status: 'not_executed'
      )
    end

    assert_match(/TC_H1/, @issue.journals.reorder(:id).last.notes)
    assert_match(/created/, @issue.journals.reorder(:id).last.notes)
  end

  def test_update_adds_a_note_with_status_change_when_setting_is_on
    enable_history
    testcase = Testcase.create!(issue: @issue, test_case_id: 'TC_H2', title: 'History', status: 'not_executed')

    assert_difference 'Journal.where(journalized_id: @issue.id, journalized_type: "Issue").count', 1 do
      testcase.update!(status: 'passed')
    end

    note = @issue.journals.reorder(:id).last.notes
    assert_match(/Not Executed \/ Not Run/, note)
    assert_match(/Passed/, note)
  end

  def test_update_without_tracked_changes_does_not_add_a_note
    enable_history
    testcase = Testcase.create!(issue: @issue, test_case_id: 'TC_H3', title: 'History', status: 'not_executed')

    assert_no_difference 'Journal.where(journalized_id: @issue.id, journalized_type: "Issue").count' do
      testcase.update!(title: 'History')
    end
  end

  def test_destroy_adds_a_note_when_setting_is_on
    enable_history
    testcase = Testcase.create!(issue: @issue, test_case_id: 'TC_H4', title: 'History', status: 'not_executed')

    assert_difference 'Journal.where(journalized_id: @issue.id, journalized_type: "Issue").count', 1 do
      testcase.destroy
    end

    assert_match(/TC_H4/, @issue.journals.reorder(:id).last.notes)
    assert_match(/deleted/, @issue.journals.reorder(:id).last.notes)
  end

  def test_no_notes_are_added_when_setting_is_off
    Setting.plugin_redmine_testcase = {
      'testcase_tracker_id' => '1',
      'log_changes_to_issue' => '0'
    }

    assert_no_difference 'Journal.where(journalized_id: @issue.id, journalized_type: "Issue").count' do
      testcase = Testcase.create!(issue: @issue, test_case_id: 'TC_H5', title: 'History', status: 'not_executed')
      testcase.update!(status: 'passed')
      testcase.destroy
    end
  end

  private

  def enable_history
    Setting.plugin_redmine_testcase = {
      'testcase_tracker_id' => '1',
      'log_changes_to_issue' => '1'
    }
  end
end
