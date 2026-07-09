module Admin
  class FeedbackStats
    def self.call(scope = Feedback.all)
      new(scope).to_h
    end

    def initialize(scope = Feedback.all)
      @scope = scope
    end

    def to_h
      {
        total: @scope.count,
        pending: @scope.pending.count,
        in_progress: @scope.in_progress.count,
        completed: @scope.completed.count,
        critical: @scope.critical_priority.count,
        feature_requests: @scope.feature_requests.count,
        bugs: @scope.bugs.count
      }
    end
  end
end
