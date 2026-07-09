namespace :google_calendar do
  desc "Authorize the configured Google account and print a refresh token"
  task authorize: :environment do
    require "googleauth"

    client_id = ENV.fetch("GOOGLE_CLIENT_ID")
    client_secret = ENV.fetch("GOOGLE_CLIENT_SECRET")
    redirect_uri = ENV.fetch("GOOGLE_OAUTH_REDIRECT_URI", "http://localhost:4567/oauth2callback")
    account_email = Meeting.company_email

    client = Google::Auth::ClientId.new(client_id, client_secret)
    authorizer = Google::Auth::UserAuthorizer.new(
      client,
      GoogleCalendarService::CALENDAR_SCOPE,
      nil,
      redirect_uri
    )

    url = authorizer.get_authorization_url(access_type: "offline", prompt: "consent")
    puts "Calendar account: #{account_email}"
    puts "1. Open this URL and sign in with #{account_email}:"
    puts url
    puts
    puts "2. After approving access, the browser redirects to localhost."
    puts "   The page may not load — that is expected."
    puts "   Copy the full URL from the address bar, or copy only the 'code' value."
    print "Paste here: "
    input = $stdin.gets.to_s.strip

    code =
      if input.blank?
        nil
      elsif input.include?("code=")
        query = input.include?("?") ? URI.parse(input).query.to_s : input
        part = query.to_s.split("&").find { |pair| pair.start_with?("code=") }
        part ? URI.decode_www_form_component(part.split("=", 2).last) : nil
      else
        input
      end

    raise "Authorization code is blank" if code.blank?

    port = URI(redirect_uri).port
    credentials = authorizer.get_credentials_from_code(
      user_id: account_email,
      code: code,
      base_url: "http://localhost:#{port}"
    )

    puts "\nRefresh token:\n#{credentials.refresh_token}"
    puts "\nAdd to .env:\nGOOGLE_REFRESH_TOKEN=#{credentials.refresh_token}"
    puts "GOOGLE_COMPANY_EMAIL=#{account_email}"
    puts "GOOGLE_CALENDAR_ID=#{account_email}"
  end

  desc "Register a Google Calendar webhook channel"
  task register_watch: :environment do
    GoogleCalendarService.new.register_webhook!
    puts "Google Calendar watch channel registered."
  end
end
