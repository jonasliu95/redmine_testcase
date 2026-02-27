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
  end
end
