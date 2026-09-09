# frozen_string_literal: true

# Two layers of bot defence for the public contact form:
#
#   * a honeypot field real users never see and never fill in
#   * Cloudflare Turnstile, once its keys are configured
#
# A tripped honeypot is answered with the normal success message so the bot has
# no signal that it was caught.
class ContactSubmissionGuard
  HONEYPOT_FIELD = :website

  def initialize(honeypot:, turnstile_token:, remote_ip:)
    @honeypot = honeypot
    @turnstile_token = turnstile_token
    @remote_ip = remote_ip
  end

  def accept?
    !honeypot_triggered? && !turnstile_failed?
  end

  def honeypot_triggered?
    @honeypot.present?
  end

  def turnstile_failed?
    TurnstileVerifier.required? &&
      !TurnstileVerifier.valid?(@turnstile_token, remote_ip: @remote_ip)
  end
end
