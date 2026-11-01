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

    # Validate settings
    def validate_settings
      missing = tracker_ids.reject { |id| Tracker.exists?(id: id) }
      missing.map do |id|
        "Configured tracker ID #{id} not found. Please reconfigure the plugin."
      end
    end
  end
end
