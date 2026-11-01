module RedmineTestcase
  module Patches
    module IssuePatch
      extend ActiveSupport::Concern

      included do
        has_many :testcases,
                 class_name: '::Testcase',
                 dependent: :destroy,
                 foreign_key: 'issue_id'
      end
    end

    # Copies test cases after Redmine has created a copied issue.
    module IssueCopyPatch
      def after_create_from_copy
        should_copy = copy? && !@after_create_from_copy_handled
        super
        if should_copy && @copied_from
          RedmineTestcase.copy_testcases_from(@copied_from, self)
        end
      end
    end
  end
end
