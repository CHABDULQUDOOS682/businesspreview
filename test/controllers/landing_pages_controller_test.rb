require "test_helper"

class LandingPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get landing_pages_show_url
    assert_response :success
  end
end
