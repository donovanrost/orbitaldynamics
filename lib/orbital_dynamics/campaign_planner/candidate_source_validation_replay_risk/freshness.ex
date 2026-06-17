defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.Freshness do
  @moduledoc false

  import OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.Common

  def risks(%{} = replay_summary) do
    if freshness_scoring_pressure?(replay_summary) do
      freshness_pressure_risk(replay_summary)
    else
      []
    end
  end

  def risks(_replay_summary), do: []

  defp freshness_scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_freshness_pressure") == true or
      Map.get(replay_summary, "branch_local_stale_pressure") == true or
      Map.get(replay_summary, "branch_local_unknown_pressure") == true or
      summary_positive?(replay_summary, "stale_reason_count") or
      summary_positive?(replay_summary, "unknown_reason_count")
  end

  defp freshness_pressure_risk(replay_summary) do
    statuses = freshness_pressure_statuses(replay_summary)

    stale_reasons =
      [
        Map.get(replay_summary, "stale_reasons"),
        replay_summary |> Map.get("stale_reason_counts", %{}) |> map_keys()
      ]
      |> List.flatten()
      |> sorted_encoded_values()

    unknown_reasons =
      [
        Map.get(replay_summary, "unknown_reasons"),
        replay_summary |> Map.get("unknown_reason_counts", %{}) |> map_keys()
      ]
      |> List.flatten()
      |> sorted_encoded_values()

    [
      %{
        "type" => "refresh_freshness_pressure",
        "severity" =>
          validation_refresh_pressure_risk_severity(%{
            "freshness_status" => freshness_pressure_priority_value(statuses),
            "state_quality_status" => freshness_pressure_priority_value(statuses),
            "required_operator_action" => "review_refresh_freshness"
          }),
        "reason" =>
          "candidate source freshness replay reports stale or unknown state-quality pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "status_counts" => Map.get(replay_summary, "status_counts"),
        "freshness_status" => freshness_pressure_priority_value(statuses),
        "freshness_statuses" => statuses,
        "state_quality_status" => freshness_pressure_priority_value(statuses),
        "stale_reason_count" => Map.get(replay_summary, "stale_reason_count"),
        "stale_reasons" => stale_reasons,
        "stale_reason_counts" => Map.get(replay_summary, "stale_reason_counts"),
        "unknown_reason_count" => Map.get(replay_summary, "unknown_reason_count"),
        "unknown_reasons" => unknown_reasons,
        "unknown_reason_counts" => Map.get(replay_summary, "unknown_reason_counts"),
        "branch_local_stale_pressure" => Map.get(replay_summary, "branch_local_stale_pressure"),
        "branch_local_unknown_pressure" =>
          Map.get(replay_summary, "branch_local_unknown_pressure"),
        "branch_local_freshness_pressure" =>
          Map.get(replay_summary, "branch_local_freshness_pressure"),
        "feedback_source" => "candidate_source.freshness_replay_summary",
        "feedback_scope" => "refresh_freshness",
        "feedback_key" => "refresh_freshness",
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp freshness_pressure_statuses(replay_summary) do
    reason_statuses =
      [
        {"stale_reason_count", "stale"},
        {"unknown_reason_count", "unknown"}
      ]
      |> Enum.flat_map(fn {field, status} ->
        if summary_positive?(replay_summary, field), do: [status], else: []
      end)

    map_statuses =
      [
        {Map.get(replay_summary, "stale_reasons"), "stale"},
        {replay_summary |> Map.get("stale_reason_counts", %{}) |> map_keys(), "stale"},
        {Map.get(replay_summary, "unknown_reasons"), "unknown"},
        {replay_summary |> Map.get("unknown_reason_counts", %{}) |> map_keys(), "unknown"}
      ]
      |> Enum.flat_map(fn
        {[], _status} -> []
        {nil, _status} -> []
        {_values, status} -> [status]
      end)

    [
      replay_summary |> Map.get("status_counts", %{}) |> map_keys(),
      reason_statuses,
      map_statuses
    ]
    |> sorted_encoded_values()
  end

  defp freshness_pressure_priority_value(statuses) do
    Enum.find(["stale", "unknown", "current"], &(&1 in statuses)) ||
      pressure_priority_value(statuses)
  end
end
