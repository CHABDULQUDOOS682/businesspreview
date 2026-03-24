require "cgi"
require "json"
require "net/http"
require "uri"

module DeveloperTasks
  class Client
    Source = Struct.new(:key, :name, :base_url, :secret, :endpoint_path, :business_id, keyword_init: true)

    def self.sources
      Business.task_sources.order(:name).map do |business|
        Source.new(
          key: business.id.to_s,
          name: business.task_source_name,
          base_url: normalized_base_url(business.task_base_url),
          secret: business.task_secret,
          endpoint_path: normalized_endpoint_path(business.task_endpoint_path),
          business_id: business.id
        )
      end
    end

    attr_reader :sources

    def initialize(sources: self.class.sources)
      @sources = Array(sources)
    end

    def fetch_tasks
      return [ [], [ "No developer task sources are configured." ] ] if sources.empty?

      tasks = []
      errors = []

      sources.each do |source|
        response = perform_request(:get, source, source.endpoint_path)
        unless response.is_a?(Net::HTTPSuccess)
          errors << response_error(source, response)
          next
        end

        tasks.concat(parse_tasks(response.body, source))
      rescue StandardError => e
        errors << "#{source.name}: #{e.message}"
      end

      [ tasks.sort_by(&:updated_sort_at).reverse, errors ]
    end

    def update_status(source_key:, id:, status:)
      source = sources.find { |item| item.key.to_s == source_key.to_s }
      return [ false, "The selected task source could not be found." ] unless source

      response = perform_request(
        :patch,
        source,
        "#{source.endpoint_path}/#{CGI.escape(id.to_s)}/status",
        form: { status: status }
      )

      return [ false, response_error(source, response) ] unless response.is_a?(Net::HTTPSuccess)

      payload = parse_json(response.body)
      [ true, build_task(extract_single_task(payload) || {}, source) ]
    rescue StandardError => e
      [ false, "#{source&.name || 'Task source'}: #{e.message}" ]
    end

    private

    def self.normalized_base_url(value)
      uri = URI.parse(value.to_s)
      return value.to_s if uri.scheme.blank? || uri.host.blank?

      "#{uri.scheme}://#{uri.host}#{":#{uri.port}" if uri.port && ![ 80, 443 ].include?(uri.port) }"
    rescue URI::InvalidURIError
      value.to_s
    end

    def self.normalized_endpoint_path(value)
      path = begin
        uri = URI.parse(value.to_s)
        uri.path.presence || value.to_s
      rescue URI::InvalidURIError
        value.to_s
      end

      candidate = path.to_s.strip
      return "/api/developer_tasks" if candidate.blank?
      return "/api/developer_tasks" if candidate == "/"

      if candidate.include?("/api/developer_tasks")
        "/#{candidate.split('/api/developer_tasks', 2).last}".prepend("/api/developer_tasks").gsub(%r{/+}, "/")
      elsif candidate.include?("/admin/developer_tasks")
        "/api/developer_tasks"
      else
        candidate.start_with?("/") ? candidate : "/#{candidate}"
      end
    end

    def parse_tasks(body, source)
      collection = extract_collection(parse_json(body))
      Array(collection).filter_map do |item|
        next unless item.is_a?(Hash)

        build_task(item, source)
      end
    end

    def build_task(item, source)
      DeveloperTask.new(
        id: value_for(item, "id", :id),
        title: value_for(item, "title", "name", "task", "summary", :title, :name),
        description: value_for(item, "description", "details", "body", "notes", :description, :details, :body),
        status: value_for(item, "status", :status),
        source_key: source.key,
        source_name: value_for(item, "source_name", "app_name", :source_name, :app_name).presence || source.name,
        priority: value_for(item, "priority", "severity", :priority, :severity),
        business_name: value_for(item, "business_name", "client_name", :business_name, :client_name) || nested_value_for(item, "business", "name"),
        assignee: value_for(item, "assignee", "assigned_to", :assignee, :assigned_to),
        external_url: value_for(item, "admin_url", "task_url", "url", :admin_url, :task_url, :url),
        created_at: parse_time(value_for(item, "created_at", "createdAt", :created_at)),
        updated_at: parse_time(value_for(item, "updated_at", "updatedAt", :updated_at)),
        raw: item
      )
    end

    def perform_request(method, source, path, form: nil)
      uri = build_uri(source.base_url, path)
      request = request_for(method, uri)
      request["Accept"] = "application/json"
      request["X-Developer-Task-Secret"] = source.secret if source.secret.present?
      request.set_form_data(form) if form.present?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 2
      http.read_timeout = 5

      http.request(request)
    end

    def build_uri(base_url, path)
      base = base_url.to_s.end_with?("/") ? base_url.to_s : "#{base_url}/"
      URI.join(base, path.sub(%r{\A/}, ""))
    end

    def request_for(method, uri)
      case method
      when :get then Net::HTTP::Get.new(uri)
      when :patch then Net::HTTP::Patch.new(uri)
      else
        raise ArgumentError, "Unsupported request method: #{method}"
      end
    end

    def parse_json(body)
      return [] if body.blank?

      JSON.parse(body)
    rescue JSON::ParserError
      []
    end

    def extract_collection(payload)
      return payload if payload.is_a?(Array)
      return payload["tasks"] if payload.is_a?(Hash) && payload["tasks"].is_a?(Array)
      return payload["developer_tasks"] if payload.is_a?(Hash) && payload["developer_tasks"].is_a?(Array)
      return payload["data"] if payload.is_a?(Hash) && payload["data"].is_a?(Array)
      return payload["results"] if payload.is_a?(Hash) && payload["results"].is_a?(Array)

      []
    end

    def extract_single_task(payload)
      return payload if payload.is_a?(Hash) && payload.key?("id")
      return payload["task"] if payload.is_a?(Hash) && payload["task"].is_a?(Hash)
      return payload["developer_task"] if payload.is_a?(Hash) && payload["developer_task"].is_a?(Hash)
      return payload["data"] if payload.is_a?(Hash) && payload["data"].is_a?(Hash)

      nil
    end

    def value_for(item, *keys)
      keys.each do |key|
        value = item[key] || item[key.to_s] || item[key.to_sym]
        return value if value.present?
      end

      nil
    end

    def nested_value_for(item, *path)
      current = item

      path.each do |segment|
        return nil unless current.is_a?(Hash)

        current = current[segment] || current[segment.to_s] || current[segment.to_sym]
      end

      current.presence
    end

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def response_error(source, response)
      detail = response.body.to_s.presence&.truncate(120)
      [ "#{source.name}: request failed with #{response.code}", detail ].compact.join(" - ")
    end
  end
end
