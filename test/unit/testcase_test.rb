require File.expand_path('../../test_helper', __FILE__)

class TestcaseTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations

  def setup
    @issue = Issue.first
    @testcase = Testcase.new(
      issue: @issue,
      test_case_id: 'TC_001',
      title: 'Test case title',
      status: 'not_executed'
    )
  end

  def test_should_be_valid
    assert @testcase.valid?
  end

  def test_should_require_issue
    @testcase.issue = nil
    assert !@testcase.valid?
    assert @testcase.errors[:issue_id].present?
  end

  def test_should_require_test_case_id
    @testcase.test_case_id = nil
    assert !@testcase.valid?
    assert @testcase.errors[:test_case_id].present?
  end

  def test_should_require_title
    @testcase.title = nil
    assert !@testcase.valid?
    assert @testcase.errors[:title].present?
  end

  def test_should_require_status
    @testcase.status = nil
    assert !@testcase.valid?
    assert @testcase.errors[:status].present?
  end

  def test_should_validate_status_inclusion
    @testcase.status = 'invalid_status'
    assert !@testcase.valid?
    assert @testcase.errors[:status].present?
  end

  def test_should_validate_test_case_id_uniqueness_per_issue
    @testcase.save!

    duplicate = Testcase.new(
      issue: @issue,
      test_case_id: 'TC_001',
      title: 'Another title',
      status: 'not_executed'
    )

    assert !duplicate.valid?
    assert duplicate.errors[:test_case_id].present?
  end

  def test_should_allow_same_test_case_id_for_different_issues
    @testcase.save!

    other_issue = Issue.last
    other_testcase = Testcase.new(
      issue: other_issue,
      test_case_id: 'TC_001',
      title: 'Same ID but different issue',
      status: 'not_executed'
    )

    assert other_testcase.valid?
  end

  def test_should_validate_length_limits
    # Test Case ID max 50
    @testcase.test_case_id = 'A' * 51
    assert !@testcase.valid?

    # Title max 255
    @testcase.test_case_id = 'TC_001'
    @testcase.title = 'A' * 256
    assert !@testcase.valid?

    # Text fields max 10000
    @testcase.title = 'Valid title'
    @testcase.preconditions = 'A' * 10001
    assert !@testcase.valid?
  end

  def test_should_set_default_position
    @testcase.save!
    assert @testcase.position > 0
  end

  def test_should_return_status_label
    @testcase.status = 'passed'
    assert_equal I18n.t('testcase_status_passed'), @testcase.status_label
  end

  def test_should_return_status_css_class
    @testcase.status = 'passed'
    assert_equal 'status-passed', @testcase.status_css_class

    @testcase.status = 'failed'
    assert_equal 'status-failed', @testcase.status_css_class
  end

  def test_should_order_by_position
    tc1 = Testcase.create!(issue: @issue, test_case_id: 'TC_001', title: 'First', status: 'not_executed', position: 1)
    tc2 = Testcase.create!(issue: @issue, test_case_id: 'TC_002', title: 'Second', status: 'not_executed', position: 2)
    tc3 = Testcase.create!(issue: @issue, test_case_id: 'TC_003', title: 'Third', status: 'not_executed', position: 3)

    testcases = @issue.testcases.to_a
    assert_equal [tc1, tc2, tc3], testcases
  end
end
