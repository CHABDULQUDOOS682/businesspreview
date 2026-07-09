if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present? && ENV["GOOGLE_REFRESH_TOKEN"].present?
  Google::Apis::RequestOptions.default.retries = 2
end
