require File.expand_path('../../test_helper', __FILE__)

class TestcaseStepTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations,
           :projects_trackers, :enabled_modules, :workflows

  def setup
    @issue = Issue.find(1)
    @testcase = Testcase.create!(
      issue: @issue,
      test_case_id: 'TC_STEP',
      title: 'Structured steps',
      status: 'not_executed'
    )
  end

  def test_should_be_valid_with_action_and_status
    step = TestcaseStep.new(testcase: @testcase, action: 'Open the page', status: 'not_executed')

    assert step.valid?
  end

  def test_should_require_action
    step = TestcaseStep.new(testcase: @testcase, status: 'not_executed')

    assert_not step.valid?
    assert step.errors[:action].present?
  end

  def test_should_require_testcase
    step = TestcaseStep.new(action: 'Open the page', status: 'not_executed')

    assert_not step.valid?
    assert step.errors[:testcase_id].present?
  end

  def test_should_validate_status_inclusion
    step = TestcaseStep.new(testcase: @testcase, action: 'Open the page', status: 'bogus')

    assert_not step.valid?
    assert step.errors[:status].present?
  end

  def test_should_assign_position_and_order_by_position
    first = TestcaseStep.create!(testcase: @testcase, action: 'First')
    second = TestcaseStep.create!(testcase: @testcase, action: 'Second')

    assert_equal 1, first.position
    assert_equal 2, second.position
    assert_equal [first, second], @testcase.testcase_steps.to_a
  end

  def test_should_be_destroyed_with_the_test_case
    TestcaseStep.create!(testcase: @testcase, action: 'First')

    assert_difference 'TestcaseStep.count', -1 do
      @testcase.destroy
    end
  end

  def test_should_return_status_label_and_css_class
    step = TestcaseStep.new(testcase: @testcase, action: 'First', status: 'passed')

    assert_equal I18n.t('testcase_status_passed'), step.status_label
    assert_equal 'status-passed', step.status_css_class
  end
end
