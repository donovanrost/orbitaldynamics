defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.RefreshBudget do
  @moduledoc false

  import OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.Common

  def risks(%{} = replay_summary) do
    if scoring_pressure?(replay_summary) do
      pressure_risk(replay_summary)
    else
      []
    end
  end

  def risks(_replay_summary), do: []

  defp scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_budget_pressure") == true or
      Map.get(replay_summary, "branch_local_dropped_candidate_pressure") == true or
      Map.get(replay_summary, "branch_local_invalid_limit_pressure") == true or
      Map.get(replay_summary, "branch_local_candidate_limit_applied") == true or
      summary_positive?(replay_summary, "dropped_candidate_count") or
      summary_positive?(replay_summary, "invalid_candidate_limit_policy_count")
  end

  defp pressure_risk(replay_summary) do
    kept_candidate_ids =
      replay_summary
      |> Map.get("kept_candidate_ids")
      |> sorted_encoded_values()

    dropped_candidate_ids =
      replay_summary
      |> Map.get("dropped_candidate_ids")
      |> sorted_encoded_values()

    candidate_limit_status = candidate_limit_status(replay_summary, dropped_candidate_ids)

    [
      %{
        "type" => "refresh_budget_pressure",
        "severity" =>
          pressure_risk_severity(%{
            "candidate_limit_status" => candidate_limit_status,
            "refresh_budget_status" => candidate_limit_status,
            "required_operator_action" => "review_refresh_budget"
          }),
        "reason" =>
          "candidate source refresh-budget replay reports dropped-candidate, invalid-limit, or candidate-limit pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "input_candidate_count" => Map.get(replay_summary, "input_candidate_count"),
        "kept_candidate_count" => Map.get(replay_summary, "kept_candidate_count"),
        "dropped_candidate_count" => Map.get(replay_summary, "dropped_candidate_count"),
        "invalid_candidate_limit_policy_count" =>
          Map.get(replay_summary, "invalid_candidate_limit_policy_count"),
        "invalid_candidate_limit_policy_reason_counts" =>
          Map.get(replay_summary, "invalid_candidate_limit_policy_reason_counts"),
        "candidate_limit_status" => candidate_limit_status,
        "refresh_budget_status" => candidate_limit_status,
        "kept_candidate_ids" => kept_candidate_ids,
        "dropped_candidate_ids" => dropped_candidate_ids,
        "branch_local_budget_pressure" => Map.get(replay_summary, "branch_local_budget_pressure"),
        "branch_local_dropped_candidate_pressure" =>
          Map.get(replay_summary, "branch_local_dropped_candidate_pressure"),
        "branch_local_invalid_limit_pressure" =>
          Map.get(replay_summary, "branch_local_invalid_limit_pressure"),
        "branch_local_candidate_limit_applied" =>
          Map.get(replay_summary, "branch_local_candidate_limit_applied"),
        "feedback_source" => "candidate_source.refresh_budget_replay_summary",
        "feedback_scope" => "refresh_budget",
        "feedback_key" => "refresh_budget",
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp candidate_limit_status(replay_summary, dropped_candidate_ids) do
    invalid_reason_counts =
      replay_summary
      |> Map.get("invalid_candidate_limit_policy_reason_counts", %{})
      |> map_keys()

    cond do
      summary_positive?(replay_summary, "invalid_candidate_limit_policy_count") or
          invalid_reason_counts != [] ->
        "invalid"

      summary_positive?(replay_summary, "dropped_candidate_count") or dropped_candidate_ids != [] ->
        "dropped"

      Map.get(replay_summary, "branch_local_candidate_limit_applied") == true ->
        "limited"

      true ->
        nil
    end
  end
end
