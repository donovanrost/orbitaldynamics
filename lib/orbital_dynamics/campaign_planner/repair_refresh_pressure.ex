defmodule OrbitalDynamics.CampaignPlanner.RepairRefreshPressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh

  alias OrbitalDynamics.CampaignPlanner.{
    RefreshFreshnessPressureEvents,
    ScalarValues
  }

  def candidate_diff_count(%{} = report) do
    case CandidateRefresh.candidate_diff_replay_summary(%{"candidate_diff_report" => report}) do
      %{"branch_local_diff_pressure" => true} -> 1
      _summary -> 0
    end
  rescue
    _error in [ArgumentError, BadMapError, FunctionClauseError] -> 0
  end

  def candidate_diff_count(_report), do: 0

  def freshness_count(%{} = report) do
    report
    |> RefreshFreshnessPressureEvents.status()
    |> ScalarValues.normalized_status_token()
    |> then(&if &1 in ["stale", "unknown"], do: 1, else: 0)
  end

  def freshness_count(_report), do: 0

  def budget_count(%{"dropped_candidate_ids" => dropped_ids}) when is_list(dropped_ids) do
    dropped_ids
    |> Enum.reject(&(&1 in [nil, ""]))
    |> length()
  end

  def budget_count(%{"dropped_candidate_count" => count})
      when is_number(count) and count > 0,
      do: trunc(count)

  def budget_count(%{"invalid_candidate_limit_policy" => true}), do: 1
  def budget_count(_report), do: 0
end
