defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ManeuverReview.Summary do
  @moduledoc false

  def summary(maneuver_summary, summary_source, replay_scope) do
    success_feedback_count =
      summary_integer(maneuver_summary, "maneuver_success_feedback_count")

    uncertainty_declared_count =
      summary_integer(maneuver_summary, "execution_uncertainty_declared_count")

    uncertainty_missing_count =
      summary_integer(maneuver_summary, "execution_uncertainty_missing_count")

    input_keys = Map.get(maneuver_summary, "input_keys", [])
    maneuver_id_counts = Map.get(maneuver_summary, "maneuver_id_counts", %{})
    required_action_counts = Map.get(maneuver_summary, "required_operator_action_counts", %{})
    maneuver_success_feedback_input? = "maneuver_success_rate" in input_keys
    maneuver_uncertainty_input? = "maneuver_execution_uncertainty" in input_keys

    %{
      "model" => "artifact_only_candidate_refresh_maneuver_review_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(maneuver_summary, "maneuver_review_report.v1"),
      "source_report_count" => summary_integer(maneuver_summary, "count"),
      "source_report_row_count" => summary_integer(maneuver_summary, "row_count"),
      "source_report_paths" => Map.get(maneuver_summary, "paths", []),
      "maneuver_success_feedback_count" => success_feedback_count,
      "execution_uncertainty_declared_count" => uncertainty_declared_count,
      "execution_uncertainty_missing_count" => uncertainty_missing_count,
      "input_keys" => input_keys,
      "maneuver_id_counts" => maneuver_id_counts,
      "required_operator_action_counts" => required_action_counts,
      "trust_boundary_status" => Map.get(maneuver_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(maneuver_summary, "trust_boundaries", []),
      "branch_local_maneuver_review_pressure" =>
        success_feedback_count + uncertainty_declared_count + uncertainty_missing_count > 0 or
          input_keys != [] or map_size(maneuver_id_counts) > 0 or
          map_size(required_action_counts) > 0,
      "branch_local_maneuver_feedback_pressure" =>
        success_feedback_count > 0 or maneuver_success_feedback_input?,
      "branch_local_maneuver_routing_pressure" => map_size(maneuver_id_counts) > 0,
      "branch_local_maneuver_action_pressure" => map_size(required_action_counts) > 0,
      "branch_local_execution_uncertainty_pressure" =>
        uncertainty_declared_count + uncertainty_missing_count > 0 or maneuver_uncertainty_input?,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_maneuver_review_replay_summary",
        "maneuver_execution" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_maneuver_review_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
