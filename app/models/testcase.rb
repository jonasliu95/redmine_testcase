class Testcase < ActiveRecord::Base
  include Redmine::Acts::Attachable

  belongs_to :issue

  # Attachments support
  acts_as_attachable view_permission: :view_test_cases,
                     delete_permission: :manage_test_cases

  # Status enumeration - defined first so validations can use it
  def self.status_values
    [
      'not_executed',
      'in_progress',
      'passed',
      'failed',
      'blocked',
      'skipped',
      'retest',
      'reopened',
      'closed'
    ]
  end

  # Validations
  validates :issue_id, presence: true
  validates :test_case_id, presence: true, length: { maximum: 50 }
  validates :title, presence: true, length: { maximum: 255 }
  validates :status, presence: true, inclusion: { in: -> { Testcase.status_values } }
  validates :test_case_id, uniqueness: { scope: :issue_id, message: :duplicate_test_case_id }

  # Soft length limits for text fields
  validates :preconditions, length: { maximum: 10000 }, allow_blank: true
  validates :steps, length: { maximum: 10000 }, allow_blank: true
  validates :expected_result, length: { maximum: 10000 }, allow_blank: true
  validates :actual_result, length: { maximum: 10000 }, allow_blank: true
  validates :comments, length: { maximum: 10000 }, allow_blank: true

  # Default scope - ordered by position
  default_scope { order(:position) }

  # Human-readable status labels
  def self.status_options
    status_values.map do |status|
      [I18n.t("testcase_status_#{status}"), status]
    end
  end

  def status_label
    I18n.t("testcase_status_#{status}")
  end

  # Required by acts_as_attachable for permission checks
  def project
    issue&.project
  end

  # Status color coding for UI
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

  # Set position before create if not set
  before_create :set_default_position

  private

  def set_default_position
    if position.nil? || position.zero?
      max_position = issue.testcases.maximum(:position) || 0
      self.position = max_position + 1
    end
  end
end
