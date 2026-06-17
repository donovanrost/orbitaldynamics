defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.ModelAcceptance do
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
    Map.get(replay_summary, "branch_local_review_pressure") == true or
      Map.get(replay_summary, "branch_local_blocking_pressure") == true or
      Map.get(replay_summary, "branch_local_unknown_model_pressure") == true or
      summary_positive?(replay_summary, "review_required_count") or
      summary_positive?(replay_summary, "blocked_count") or
      summary_positive?(replay_summary, "unknown_model_count")
  end

  defp pressure_risk(replay_summary) do
    statuses = pressure_statuses(replay_summary)
    intended_uses = replay_summary |> Map.get("intended_use_counts", %{}) |> map_keys()
    validation_levels = replay_summary |> Map.get("validation_level_counts", %{}) |> map_keys()

    model_ids =
      [
        replay_summary |> Map.get("model_ids_by_status", %{}) |> Map.values(),
        replay_summary |> Map.get("model_ids_by_validation_level", %{}) |> Map.values(),
        replay_summary |> Map.get("model_ids_by_intended_use", %{}) |> Map.values()
      ]
      |> List.flatten()
      |> sorted_encoded_values()

    [
      %{
        "type" => "model_acceptance_pressure",
        "severity" =>
          pressure_risk_severity(%{
            "model_acceptance_status" => pressure_priority_value(statuses),
            "model_status" => pressure_priority_value(statuses),
            "validation_level" => pressure_priority_value(validation_levels)
          }),
        "reason" =>
          "candidate source model-acceptance replay reports review, blocking, or unknown-model pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_record_count" => Map.get(replay_summary, "source_report_record_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "intended_use_counts" => Map.get(replay_summary, "intended_use_counts"),
        "status_counts" => Map.get(replay_summary, "status_counts"),
        "validation_level_counts" => Map.get(replay_summary, "validation_level_counts"),
        "model_count" => Map.get(replay_summary, "model_count"),
        "accepted_count" => Map.get(replay_summary, "accepted_count"),
        "review_required_count" => Map.get(replay_summary, "review_required_count"),
        "blocked_count" => Map.get(replay_summary, "blocked_count"),
        "unknown_model_count" => Map.get(replay_summary, "unknown_model_count"),
        "model_ids_by_status" => Map.get(replay_summary, "model_ids_by_status"),
        "model_ids_by_validation_level" =>
          Map.get(replay_summary, "model_ids_by_validation_level"),
        "model_ids_by_intended_use" => Map.get(replay_summary, "model_ids_by_intended_use"),
        "model_ids" => model_ids,
        "intended_uses" => intended_uses,
        "model_acceptance_statuses" => statuses,
        "validation_levels" => validation_levels,
        "model_acceptance_status" => pressure_priority_value(statuses),
        "model_status" => pressure_priority_value(statuses),
        "validation_level" => pressure_priority_value(validation_levels),
        "branch_local_review_pressure" => Map.get(replay_summary, "branch_local_review_pressure"),
        "branch_local_blocking_pressure" =>
          Map.get(replay_summary, "branch_local_blocking_pressure"),
        "branch_local_unknown_model_pressure" =>
          Map.get(replay_summary, "branch_local_unknown_model_pressure"),
        "feedback_source" => "candidate_source.model_acceptance_replay_summary",
        "feedback_scope" => "model_acceptance",
        "feedback_key" => "model_acceptance",
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp pressure_statuses(replay_summary) do
    count_statuses =
      [
        {"blocked_count", "blocked"},
        {"review_required_count", "review_required"},
        {"accepted_count", "accepted"}
      ]
      |> Enum.flat_map(fn {field, status} ->
        if summary_positive?(replay_summary, field), do: [status], else: []
      end)

    [
      replay_summary |> Map.get("status_counts", %{}) |> map_keys(),
      replay_summary |> Map.get("model_ids_by_status", %{}) |> map_keys(),
      count_statuses
    ]
    |> sorted_encoded_values()
  end
end
