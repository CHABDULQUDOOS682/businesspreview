require "rails_helper"

RSpec.describe DeveloperTasks::Client do
  let!(:business) { create(:business, task_source_enabled: true, task_base_url: "https://api.github.com", task_secret: "secret", task_endpoint_path: "/tasks") }
  let(:client) { DeveloperTasks::Client.new }

  describe "#fetch_tasks" do
    let(:success_body) { [{ id: "1", title: "Task 1", status: "pending" }].to_json }

    it "returns tasks when the request is successful" do
      stub_request(:get, "https://api.github.com/tasks")
        .with(headers: { "X-Developer-Task-Secret" => "secret" })
        .to_return(status: 200, body: success_body)

      tasks, errors = client.fetch_tasks
      expect(tasks.first.title).to eq("Task 1")
      expect(errors).to be_empty
    end

    it "appends error when the response is not a success" do
      # Covers lines 38-39: errors << response_error(source, response); next
      stub_request(:get, "https://api.github.com/tasks")
        .to_return(status: 500, body: "Internal Server Error")

      tasks, errors = client.fetch_tasks
      expect(tasks).to be_empty
      expect(errors.first).to include("500")
    end

    it "handles JSON parsing errors" do
      stub_request(:get, "https://api.github.com/tasks").to_return(status: 200, body: "invalid json")
      tasks, errors = client.fetch_tasks
      expect(tasks).to be_empty
    end

    it "handles standard errors during request" do
      stub_request(:get, "https://api.github.com/tasks").to_raise(StandardError.new("Network failure"))
      _tasks, errors = client.fetch_tasks
      expect(errors.first).to include("Network failure")
    end

    it "returns early if no sources are configured" do
      allow(DeveloperTasks::Client).to receive(:sources).and_return([])
      tasks, errors = DeveloperTasks::Client.new.fetch_tasks
      expect(tasks).to be_empty
      expect(errors.first).to include("No developer task sources")
    end
  end

  describe "#update_status" do
    it "updates the status successfully" do
      stub_request(:patch, "https://api.github.com/tasks/1/status")
        .to_return(status: 200, body: { task: { id: "1", status: "completed" } }.to_json) # Test nested 'task' extraction

      success, payload = client.update_status(source_key: business.id.to_s, id: "1", status: "completed")
      expect(success).to be true
      expect(payload.status).to eq("completed")
    end

    it "handles nested 'developer_task' extraction" do
      stub_request(:patch, "https://api.github.com/tasks/1/status")
        .to_return(status: 200, body: { developer_task: { id: "1", status: "completed" } }.to_json)

      success, payload = client.update_status(source_key: business.id.to_s, id: "1", status: "completed")
      expect(success).to be true
    end

    it "handles nested 'data' extraction" do
      stub_request(:patch, "https://api.github.com/tasks/1/status")
        .to_return(status: 200, body: { data: { id: "1", status: "completed" } }.to_json)

      success, payload = client.update_status(source_key: business.id.to_s, id: "1", status: "completed")
      expect(success).to be true
    end

    it "returns false when the request fails" do
      stub_request(:patch, "https://api.github.com/tasks/1/status").to_return(status: 400, body: "Bad request")
      success, payload = client.update_status(source_key: business.id.to_s, id: "1", status: "completed")
      expect(success).to be false
      expect(payload).to include("400")
    end

    it "returns false when the source key is invalid" do
      success, payload = client.update_status(source_key: "invalid", id: "1", status: "completed")
      expect(success).to be false
      expect(payload).to include("not be found")
    end

    it "handles exceptions" do
      allow(client).to receive(:perform_request).and_raise(StandardError.new("Boom"))
      success, payload = client.update_status(source_key: business.id.to_s, id: "1", status: "completed")
      expect(success).to be false
      expect(payload).to include("Boom")
    end
  end

  describe "normalization" do
    it "normalizes base urls" do
      expect(DeveloperTasks::Client.normalized_base_url("github.com")).to eq("github.com")
      expect(DeveloperTasks::Client.normalized_base_url("https://api.github.com:8080/path")).to eq("https://api.github.com:8080")
      expect(DeveloperTasks::Client.normalized_base_url("invalid uri")).to eq("invalid uri")
    end

    it "excludes standard ports (80, 443) from normalized base url" do
      expect(DeveloperTasks::Client.normalized_base_url("https://api.example.com")).to eq("https://api.example.com")
      expect(DeveloperTasks::Client.normalized_base_url("http://api.example.com")).to eq("http://api.example.com")
    end

    it "normalizes endpoint paths" do
      expect(DeveloperTasks::Client.normalized_endpoint_path("")).to eq("/api/developer_tasks")
      expect(DeveloperTasks::Client.normalized_endpoint_path("/")).to eq("/api/developer_tasks")
      expect(DeveloperTasks::Client.normalized_endpoint_path("/admin/developer_tasks")).to eq("/api/developer_tasks")
      expect(DeveloperTasks::Client.normalized_endpoint_path("/api/developer_tasks/extra")).to eq("/api/developer_tasks/extra")
      expect(DeveloperTasks::Client.normalized_endpoint_path("tasks")).to eq("/tasks")
      expect(DeveloperTasks::Client.normalized_endpoint_path("http://example.com/api")).to eq("/api")
    end

    it "handles URI::InvalidURIError in normalized_endpoint_path" do
      # Spaces in the string cause URI::InvalidURIError, exercising lines 84-85
      result = DeveloperTasks::Client.normalized_endpoint_path("invalid path with spaces")
      expect(result).to eq("/invalid path with spaces")
    end

    it "handles endpoint path starting with slash in the else branch" do
      # Covers candidate.start_with?("/") ? candidate branch
      expect(DeveloperTasks::Client.normalized_endpoint_path("/custom/path")).to eq("/custom/path")
    end
  end

  describe "extraction" do
    it "extracts collections from various payload formats" do
      expect(client.send(:extract_collection, { "tasks" => [] })).to eq([])
      expect(client.send(:extract_collection, { "developer_tasks" => [] })).to eq([])
      expect(client.send(:extract_collection, { "data" => [] })).to eq([])
      expect(client.send(:extract_collection, { "results" => [] })).to eq([])
      expect(client.send(:extract_collection, "invalid")).to eq([])
    end

    it "skips non-Hash items when parsing tasks" do
      # Covers: next unless item.is_a?(Hash) — line 104
      mixed_body = [nil, "string", 42, { id: "1", title: "Valid Task", status: "open" }].to_json
      stub_request(:get, "https://api.github.com/tasks")
        .to_return(status: 200, body: mixed_body)

      tasks, errors = client.fetch_tasks
      expect(tasks.size).to eq(1)
      expect(tasks.first.title).to eq("Valid Task")
      expect(errors).to be_empty
    end
  end

  describe "parsing" do
    it "parses time values safely" do
      expect(client.send(:parse_time, nil)).to be_nil
      expect(client.send(:parse_time, "invalid")).to be_nil
      expect(client.send(:parse_time, Time.now.to_s)).to be_a(Time)
    end

    it "returns nil when time parsing raises a TypeError" do
      allow(Time.zone).to receive(:parse).and_raise(TypeError)

      expect(client.send(:parse_time, "2026-05-12")).to be_nil
    end
  end

  describe "requests" do
    it "raises error for unsupported methods" do
      expect {
        client.send(:request_for, :post, URI("http://example.com"))
      }.to raise_error(ArgumentError)
    end
  end

  describe "#nested_value_for" do
    it "returns nil when an intermediate value is not a Hash" do
      # Covers: return nil unless current.is_a?(Hash) — line 197
      item = { "business" => "a string, not a hash" }
      result = client.send(:nested_value_for, item, "business", "name")
      expect(result).to be_nil
    end

    it "traverses nested hashes correctly" do
      item = { "business" => { "name" => "Acme" } }
      result = client.send(:nested_value_for, item, "business", "name")
      expect(result).to eq("Acme")
    end
  end
end
