require File.expand_path('../../test_helper', __FILE__)

class AccessControlTest < ActiveSupport::TestCase
  def test_manage_test_cases_requires_login
    permission = Redmine::AccessControl.permission(:manage_test_cases)

    assert_not_nil permission
    assert permission.require_loggedin?
  end
end
