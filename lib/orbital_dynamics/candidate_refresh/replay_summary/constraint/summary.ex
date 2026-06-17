defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Constraint.Summary do
  @moduledoc false

  def summary(constraint_summary, summary_source, replay_scope) do
    downlink_gap_count = summary_integer(constraint_summary, "downlink_gap_row_count")
    resource_margin_count = summary_integer(constraint_summary, "resource_margin_row_count")
    status_counts = Map.get(constraint_summary, "status_counts", %{})
    ground_station_counts = Map.get(constraint_summary, "ground_station_counts", %{})
    metric_counts = Map.get(constraint_summary, "constraint_metric_counts", %{})
    constraint_id_counts = Map.get(constraint_summary, "constraint_id_counts", %{})
    source_activity_id_counts = Map.get(constraint_summary, "source_activity_id_counts", %{})
    resource_counts = Map.get(constraint_summary, "constraint_resource_counts", %{})
    spacecraft_counts = Map.get(constraint_summary, "constraint_spacecraft_counts", %{})

    resource_margin_pressure =
      resource_margin_count > 0 or map_size(resource_counts) > 0 or
        map_size(spacecraft_counts) > 0

    constraint_routing_pressure =
      map_size(ground_station_counts) > 0 or map_size(metric_counts) > 0 or
        map_size(constraint_id_counts) > 0 or map_size(source_activity_id_counts) > 0 or
        map_size(resource_counts) > 0 or map_size(spacecraft_counts) > 0

    %{
      "model" => "artifact_only_candidate_refresh_constraint_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(constraint_summary, "constraint_report.v1"),
      "source_report_count" => summary_integer(constraint_summary, "count"),
      "source_report_row_count" => summary_integer(constraint_summary, "row_count"),
      "source_report_paths" => Map.get(constraint_summary, "paths", []),
      "downlink_gap_row_count" => downlink_gap_count,
      "resource_margin_row_count" => resource_margin_count,
      "status_counts" => status_counts,
      "ground_station_counts" => ground_station_counts,
      "constraint_metric_counts" => metric_counts,
      "constraint_id_counts" => constraint_id_counts,
      "source_activity_id_counts" => source_activity_id_counts,
      "constraint_resource_counts" => resource_counts,
      "constraint_spacecraft_counts" => spacecraft_counts,
      "trust_boundary_status" => Map.get(constraint_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(constraint_summary, "trust_boundaries", []),
      "branch_local_constraint_pressure" =>
        downlink_gap_count > 0 or map_size(status_counts) > 0 or resource_margin_pressure or
          constraint_routing_pressure,
      "branch_local_downlink_gap_pressure" => downlink_gap_count > 0,
      "branch_local_resource_margin_pressure" => resource_margin_pressure,
      "branch_local_constraint_routing_pressure" => constraint_routing_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_constraint_replay_summary",
        "objective_generation" => "not_performed_by_summary",
        "resource_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_constraint_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    summary
    |> Map.get("contract")
    |> case do
      nil -> default_contract
      contract -> contract
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
        case Integer.parse(value) do
          {parsed, ""} -> parsed
          _other -> 0
        end

      _other ->
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
