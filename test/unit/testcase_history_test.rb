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

  def test_destroying_an_issue_with_test_cases_does_not_raise_or_add_a_note
    enable_history
    testcase = Testcase.create!(issue: @issue, test_case_id: 'TC_H6', title: 'History', status: 'not_executed')
    TestcaseStep.create!(testcase: testcase, action: 'A step')
    issue_id = @issue.id
    original_notified_events = Setting.notified_events
    Setting.notified_events = []

    assert_nothing_raised do
      @issue.destroy
    end

    assert_not Issue.exists?(issue_id)
    assert_equal 0, Journal.where(journalized_id: issue_id, journalized_type: 'Issue').count
  ensure
    Setting.notified_events = original_notified_events
  end

  def test_update_from_nil_to_blank_does_not_add_a_note
    enable_history
    testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_H7',
      title: 'History',
      status: 'not_executed',
      comments: nil
    )

    assert_no_difference 'Journal.where(journalized_id: @issue.id, journalized_type: "Issue").count' do
      testcase.update!(comments: '')
    end
  end

  def test_update_with_only_line_ending_changes_does_not_add_a_note
    enable_history
    testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_H8',
      title: 'History',
      status: 'not_executed',
      comments: "line one\r\nline two"
    )

    assert_no_difference 'Journal.where(journalized_id: @issue.id, journalized_type: "Issue").count' do
      testcase.update!(comments: "line one\nline two")
    end
  end

  def test_update_from_blank_to_text_adds_a_note
    enable_history
    testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_H9',
      title: 'History',
      status: 'not_executed',
      comments: ''
    )

    assert_difference 'Journal.where(journalized_id: @issue.id, journalized_type: "Issue").count', 1 do
      testcase.update!(comments: 'A real comment')
    end

    assert_match(/A real comment/, @issue.journals.reorder(:id).last.notes)
  end

  private

  def enable_history
    Setting.plugin_redmine_testcase = {
      'testcase_tracker_id' => '1',
      'log_changes_to_issue' => '1'
    }
  end
end
