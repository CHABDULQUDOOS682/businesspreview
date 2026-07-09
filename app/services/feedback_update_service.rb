class FeedbackUpdateService
  def initialize(feedback:, attributes:, screenshots: nil, remove_screenshot_ids: [])
    @feedback = feedback
    @attributes = attributes
    @screenshots = screenshots
    @remove_screenshot_ids = Array(remove_screenshot_ids).map(&:to_s)
    @previous_status = feedback.status
  end

  def call
    @feedback.transaction do
      purge_removed_screenshots!
      attach_new_screenshots!
      @feedback.assign_attributes(@attributes)
      apply_resolution_timestamp!
      @feedback.save!
      notify_creator_if_status_changed!
      @feedback
    end
  end

  private

  def purge_removed_screenshots!
    return if @remove_screenshot_ids.blank?

    @feedback.screenshots.each do |screenshot|
      screenshot.purge if @remove_screenshot_ids.include?(screenshot.id.to_s)
    end
  end

  def attach_new_screenshots!
    return if @screenshots.blank?

    @feedback.screenshots.attach(@screenshots)
  end

  def apply_resolution_timestamp!
    if Feedback::RESOLVED_STATUSES.include?(@feedback.status)
      @feedback.resolved_at = Time.current
    elsif @feedback.will_save_change_to_status?
      @feedback.resolved_at = nil
    end
  end

  def notify_creator_if_status_changed!
    return unless @feedback.saved_change_to_status?
    return if @previous_status == @feedback.status

    FeedbackMailer.status_changed(@feedback).deliver_later
  end
end
