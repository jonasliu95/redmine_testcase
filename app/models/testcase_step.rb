class TestcaseStep < ApplicationRecord
  belongs_to :testcase

  validates :testcase, presence: true
  validates :action, presence: true, length: { maximum: 10000 }
  validates :test_data, length: { maximum: 10000 }, allow_blank: true
  validates :expected_result, length: { maximum: 10000 }, allow_blank: true
  validates :actual_result, length: { maximum: 10000 }, allow_blank: true
  validates :status, presence: true, inclusion: { in: -> { Testcase.status_values } }

  default_scope { order(:position) }

  before_validation :set_default_status
  before_create :set_default_position

  def status_label
    I18n.t("testcase_status_#{status}")
  end

  def status_css_class
    case status
    when 'passed'
      'status-passed'
    when 'failed'
      'status-failed'
    when 'blocked'
      'status-blocked'
    when 'in_progress'
      'status-in-progress'
    when 'not_executed'
      'status-not-executed'
    when 'skipped'
      'status-skipped'
    when 'retest'
      'status-retest'
    when 'reopened'
      'status-reopened'
    when 'closed'
      'status-closed'
    else
      'status-default'
    end
  end

  private

  def set_default_status
    self.status = 'not_executed' if status.blank?
  end

  def set_default_position
    if position.nil? || position.zero?
      self.position = (testcase&.testcase_steps&.maximum(:position) || 0) + 1
    end
  end
end
