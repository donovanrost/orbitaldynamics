defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionStatusTokens do
  @moduledoc false

  @met_tokens ["satisfied", "complete", "completed", "selected", "met"]

  @unmet_tokens [
    "unsatisfied",
    "not_satisfied",
    "not_met",
    "missing",
    "missed",
    "failed",
    "late",
    "overdue",
    "violated",
    "breached"
  ]

  @partial_tokens [
    "partial",
    "shortfall",
    "insufficient",
    "below_target",
    "below_threshold",
    "under_target",
    "under_threshold",
    "gap",
    "has_gap",
    "at_risk",
    "needs_replan",
    "needs_refresh",
    "requires_attention",
    "degraded",
    "behind_plan"
  ]

  @candidate_available_tokens [
    "candidate_found",
    "candidate_window_available",
    "viable_candidate"
  ]

  @no_candidate_window_tokens ["no_candidate", "no_window", "no_viable_candidate"]

  def status_value(status) when status in @met_tokens, do: "met"
  def status_value(status) when status in @unmet_tokens, do: "unmet"
  def status_value(status) when status in @partial_tokens, do: "partial"
  def status_value(status) when status in @candidate_available_tokens, do: "candidate_available"
  def status_value(status) when status in @no_candidate_window_tokens, do: "no_candidate_window"
  def status_value(status), do: status
end
