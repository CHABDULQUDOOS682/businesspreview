require "test_helper"

class HomePagesControllerTest < ActionDispatch::IntegrationTest
  test "renders public marketing pages" do
    [ root_path, services_path, about_path, process_path, pricing_path, portfolio_path, contact_path, privacy_path ].each do |path|
      get path
      assert_response :success, "#{path} should respond successfully"
    end
  end
end
