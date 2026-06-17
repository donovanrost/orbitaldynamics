defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.Summary do
  @moduledoc false

  def summary(filter_summary, summary_source, replay_scope) do
    suppressed_candidate_count =
      summary_integer(filter_summary, "suppressed_candidate_count")

    invalid_resource_summary_input_count =
      summary_integer(filter_summary, "invalid_resource_summary_input_count")

    invalid_resource_summary_input_ids =
      Map.get(filter_summary, "invalid_resource_summary_input_ids")

    suppressed_reason_counts = Map.get(filter_summary, "suppressed_reason_counts", %{})

    spacecraft_counts =
      Map.get(filter_summary, "resource_filter_spacecraft_counts", %{})

    resource_counts =
      Map.get(filter_summary, "resource_filter_resource_counts", %{})

    blocking_dimension_counts =
      Map.get(filter_summary, "resource_filter_blocking_dimension_counts", %{})

    candidate_ids_by_spacecraft = Map.get(filter_summary, "candidate_ids_by_spacecraft", %{})
    candidate_ids_by_resource = Map.get(filter_summary, "candidate_ids_by_resource", %{})

    candidate_ids_by_blocking_dimension =
      Map.get(filter_summary, "candidate_ids_by_blocking_dimension", %{})

    direction_counts = Map.get(filter_summary, "direction_counts", %{})
    directions = Map.get(filter_summary, "directions", [])
    candidate_ids_by_direction = Map.get(filter_summary, "candidate_ids_by_direction", %{})
    direction_routing = Map.get(filter_summary, "direction_routing", %{})

    candidate_ids_by_suppressed_reason =
      Map.get(filter_summary, "candidate_ids_by_suppressed_reason", %{})

    source_report_paths = Map.get(filter_summary, "paths") || []

    %{
      "model" => "artifact_only_candidate_refresh_resource_filter_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(filter_summary, "resource_filter_report.v1"),
      "source_report_count" => summary_integer(filter_summary, "count"),
      "source_report_row_count" => summary_integer(filter_summary, "row_count"),
      "source_report_paths" => source_report_paths,
      "suppressed_candidate_count" => suppressed_candidate_count,
      "invalid_resource_summary_input_count" => invalid_resource_summary_input_count,
      "invalid_resource_summary_input_ids" => invalid_resource_summary_input_ids,
      "suppressed_reason_counts" => suppressed_reason_counts,
      "candidate_ids_by_suppressed_reason" => candidate_ids_by_suppressed_reason,
      "resource_filter_spacecraft_counts" => spacecraft_counts,
      "candidate_ids_by_spacecraft" => candidate_ids_by_spacecraft,
      "resource_filter_resource_counts" => resource_counts,
      "candidate_ids_by_resource" => candidate_ids_by_resource,
      "resource_filter_blocking_dimension_counts" => blocking_dimension_counts,
      "candidate_ids_by_blocking_dimension" => candidate_ids_by_blocking_dimension,
      "direction_counts" => direction_counts,
      "directions" => directions,
      "candidate_ids_by_direction" => candidate_ids_by_direction,
      "direction_routing" => direction_routing,
      "trust_boundary_status" => Map.get(filter_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(filter_summary, "trust_boundaries", []),
      "branch_local_resource_filter_pressure" =>
        suppressed_candidate_count + invalid_resource_summary_input_count > 0 or
          map_size(suppressed_reason_counts) > 0 or map_size(spacecraft_counts) > 0 or
          map_size(resource_counts) > 0 or map_size(blocking_dimension_counts) > 0 or
          map_size(candidate_ids_by_spacecraft) > 0 or map_size(candidate_ids_by_resource) > 0 or
          map_size(candidate_ids_by_blocking_dimension) > 0 or
          map_size(direction_counts) > 0 or length(List.wrap(directions)) > 0 or
          map_size(candidate_ids_by_direction) > 0 or map_size(direction_routing) > 0 or
          map_size(candidate_ids_by_suppressed_reason) > 0 or
          invalid_resource_summary_input_ids not in [nil, []],
      "branch_local_candidate_suppression_pressure" =>
        suppressed_candidate_count > 0 or map_size(suppressed_reason_counts) > 0 or
          map_size(candidate_ids_by_spacecraft) > 0 or map_size(candidate_ids_by_resource) > 0 or
          map_size(candidate_ids_by_blocking_dimension) > 0 or
          map_size(candidate_ids_by_suppressed_reason) > 0 or map_size(direction_counts) > 0 or
          length(List.wrap(directions)) > 0 or map_size(candidate_ids_by_direction) > 0 or
          map_size(direction_routing) > 0,
      "branch_local_invalid_resource_summary_pressure" =>
        invalid_resource_summary_input_count > 0 or
          invalid_resource_summary_input_ids not in [nil, []],
      "branch_local_resource_blocking_pressure" =>
        map_size(spacecraft_counts) > 0 or map_size(resource_counts) > 0 or
          map_size(blocking_dimension_counts) > 0 or map_size(candidate_ids_by_spacecraft) > 0 or
          map_size(candidate_ids_by_resource) > 0 or
          map_size(candidate_ids_by_blocking_dimension) > 0,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_resource_filter_replay_summary",
        "resource_filter" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_resource_filter_replay_summary",
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
