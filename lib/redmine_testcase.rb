module RedmineTestcase
  # Plugin configuration and utilities

  class << self
    # Check if a tracker is configured for test cases
    def tracker_configured?
      tracker_id.present?
    end

    # Get the configured tracker ID
    def tracker_id
      Setting.plugin_redmine_testcase['testcase_tracker_id']
    end

    # Get the configured tracker object
    def tracker
      return nil unless tracker_configured?
      begin
        Tracker.find(tracker_id)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

    # Check if an issue should have test cases enabled
    def enabled_for_issue?(issue)
      return false unless tracker_configured?
      return false unless issue
      issue.tracker_id.to_s == tracker_id.to_s
    end

    # Validate settings
    def validate_settings
      errors = []

      if tracker_configured?
        unless tracker
          errors << "Configured tracker ID #{tracker_id} not found. Please reconfigure the plugin."
        end
      end

      errors
    end
  end
end
