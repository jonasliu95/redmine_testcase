class Testcase < ApplicationRecord
  belongs_to :issue

  # Attachments support
  acts_as_attachable view_permission: :view_test_cases,
                     edit_permission: :manage_test_cases,
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

  # Single grouped query summary used by the controller and views.
  def self.summary(scope = all)
    counts = scope.reorder(nil).group(:status).count
    total = counts.values.sum
    by_status = status_values.index_with { |status| counts[status] || 0 }

    {
      total: total,
      by_status: by_status,
      pass_rate: total > 0 ? (by_status['passed'].to_f / total * 100).round(1) : 0
    }
  end

  def status_label
    I18n.t("testcase_status_#{status}")
  end

  # Required by acts_as_attachable for permission checks
  def project
    issue&.project
  end

  # Required by the core attachments controller when Testcase is used as a container.
  def visible?(user = User.current)
    issue.present? && issue.visible?(user) && user.allowed_to?(:view_test_cases, project)
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

  # Optional issue journal notes (disabled by default because they send emails)
  attr_accessor :skip_issue_journal

  HISTORY_FIELDS = {
    'test_case_id' => :label_test_case_id,
    'title' => :label_test_case_title,
    'preconditions' => :label_test_case_preconditions,
    'steps' => :label_test_case_steps,
    'expected_result' => :label_test_case_expected,
    'actual_result' => :label_test_case_actual,
    'status' => :label_test_case_status,
    'comments' => :label_test_case_comments
  }.freeze

  after_create :add_created_note
  after_update :add_updated_note
  after_destroy :add_destroyed_note

  private

  def set_default_position
    if position.nil? || position.zero?
      max_position = issue.testcases.maximum(:position) || 0
      self.position = max_position + 1
    end
  end

  def add_created_note
    add_issue_note(
      I18n.t(:text_testcase_created_note, test_case_id: test_case_id, title: title)
    )
  end

  def add_updated_note
    changes = saved_changes.slice(*HISTORY_FIELDS.keys).reject do |field, (old_value, new_value)|
      history_values_equal?(field, old_value, new_value)
    end
    return if changes.empty?

    parts = changes.map do |field, (old_value, new_value)|
      I18n.t(
        :text_testcase_change,
        field: I18n.t(HISTORY_FIELDS[field]),
        old: history_value(field, old_value),
        new: history_value(field, new_value)
      )
    end

    add_issue_note(
      I18n.t(
        :text_testcase_changed_note,
        test_case_id: test_case_id,
        title: title,
        changes: parts.join('; ')
      )
    )
  end

  def add_destroyed_note
    add_issue_note(
      I18n.t(:text_testcase_deleted_note, test_case_id: test_case_id, title: title)
    )
  end

  def add_issue_note(notes)
    return if skip_issue_journal
    return if destroyed_by_association

    RedmineTestcase.add_note_to_issue(issue_id, notes)
  end

  def history_values_equal?(field, old_value, new_value)
    return old_value.to_s == new_value.to_s if field == 'status'

    old_text = normalize_history_text(old_value)
    new_text = normalize_history_text(new_value)
    old_text == new_text || (old_text.blank? && new_text.blank?)
  end

  def normalize_history_text(value)
    value.to_s.gsub(/\r\n?/, "\n")
  end

  def history_value(field, value)
    if field == 'status'
      value.present? ? I18n.t("testcase_status_#{value}") : '-'
    else
      value.presence || '-'
    end
  end
end
