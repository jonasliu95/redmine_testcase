module RedmineTestcase
  # Plugin configuration and utilities

  class << self
    # Trackers enabled for test cases.
    #
    # The plural setting takes precedence whenever its key is present, even
    # when it is empty: that is how an admin disables all trackers. Legacy
    # installs only have testcase_tracker_id, so fall back to it.
    def tracker_ids
      settings = Setting.plugin_redmine_testcase || {}
      ids =
        if settings.key?('testcase_tracker_ids')
          Array(settings['testcase_tracker_ids'])
        else
          [settings['testcase_tracker_id']]
        end

      ids.map { |id| id.to_s.strip }.reject(&:blank?).uniq
    end

    def tracker_configured?
      tracker_ids.any?
    end

    # Get the configured tracker objects
    def trackers
      Tracker.where(id: tracker_ids).sorted
    end

    # Check if an issue should have test cases enabled
    def enabled_for_issue?(issue)
      return false unless issue

      tracker_ids.include?(issue.tracker_id.to_s)
    end

    # Copy all test cases (and their attachments) from source_issue to
    # target_issue. Used when Redmine copies an issue.
    def copy_testcases_from(source_issue, target_issue)
      return unless source_issue && target_issue
      return unless enabled_for_issue?(target_issue)

      source_issue.testcases.includes(:attachments).each do |source|
        copy = source.dup
        copy.assign_attributes(
          issue_id: target_issue.id,
          status: 'not_executed',
          actual_result: nil,
          position: source.position,
          created_at: nil,
          updated_at: nil
        )
        copy.skip_issue_journal = true if copy.respond_to?(:skip_issue_journal=)

        unless copy.save
          log_copy_error(target_issue, source, copy.errors.full_messages)
          next
        end

        copy.attachments = source.attachments.map { |attachment| attachment.copy(container: copy) }

        source.testcase_steps.each do |step|
          step_copy = step.dup
          step_copy.assign_attributes(
            status: 'not_executed',
            actual_result: nil,
            position: step.position,
            created_at: nil,
            updated_at: nil
          )
          copy.testcase_steps << step_copy
        end
      end
    rescue StandardError => e
      details = e.message.to_s
      Rails.logger.error(
        "[redmine_testcase] Could not copy test cases to issue ##{target_issue&.id}: #{e.class}: #{details}"
      )
    end

    def log_copy_error(target_issue, source, messages)
      Rails.logger.error(
        "[redmine_testcase] Could not copy test case ##{source.id} to issue ##{target_issue.id}: #{messages.join(', ')}"
      )
    end

    # Validate settings
    def validate_settings
      missing = tracker_ids.reject { |id| Tracker.exists?(id: id) }
      missing.map do |id|
        "Configured tracker ID #{id} not found. Please reconfigure the plugin."
      end
    end

    # Active projects that allow at least one of the enabled trackers but have
    # not enabled the "Test cases" project module, so the feature stays hidden.
    def projects_without_module
      return Project.none unless tracker_configured?

      with_module = EnabledModule.where(name: 'test_cases').select(:project_id)
      with_tracker = Project.joins(:trackers).where(trackers: {id: tracker_ids}).select('projects.id')
      Project.active.where(id: with_tracker).where.not(id: with_module).sorted
    end

    # Whether test case changes should be written to the parent issue journal.
    def log_changes?
      (Setting.plugin_redmine_testcase || {})['log_changes_to_issue'].to_s == '1'
    end

    # Add a note to an issue journal as the current user. Used by test case
    # callbacks and by the controller for bulk updates (which skip callbacks).
    def add_note_to_issue(issue_id, notes)
      return false unless log_changes?
      return false unless User.current&.logged?

      parent = Issue.find_by(id: issue_id)
      return false unless parent

      parent.init_journal(User.current, notes)
      unless parent.save
        Rails.logger.error(
          "[redmine_testcase] Could not add history note to issue ##{parent.id}: " \
            "#{parent.errors.full_messages.join(', ')}"
        )
        return false
      end
      true
    rescue StandardError => e
      details = e.message.to_s
      Rails.logger.error(
        "[redmine_testcase] Could not add history note to issue ##{issue_id}: #{e.class}: #{details}"
      )
      false
    end
  end
end
