defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      count_source_report_values: 1,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      numeric_report_count: 2,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    direction_counts =
      reports
      |> Enum.map(&resource_filter_report_direction_counts(&1, callbacks))
      |> merge_count_maps()

    candidate_ids_by_direction =
      reports
      |> Enum.map(&resource_filter_report_candidate_ids_by_direction(&1, callbacks))
      |> merge_string_list_maps()

    directions =
      resource_filter_report_direction_keys(direction_counts, candidate_ids_by_direction)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => resource_filter_input_summary_contract(reports),
      "count" => length(sources),
      "source_summary_model_counts" => count_report_field_values(reports, "source_summary_model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(reports, "source_summary_schema_contract"),
      "source_artifact_type_counts" => count_report_field_values(reports, "source_artifact_type"),
      "row_count" => sum_report_count(reports, &row_count/1),
      "suppressed_candidate_count" => sum_report_count(reports, &suppressed_candidate_count/1),
      "invalid_resource_summary_input_count" =>
        sum_report_count(reports, &invalid_resource_summary_input_count/1),
      "invalid_resource_summary_input_ids" =>
        reports
        |> Enum.flat_map(&invalid_resource_summary_input_ids(&1, callbacks))
        |> sorted_string_values()
        |> case do
          [] -> nil
          ids -> ids
        end,
      "suppressed_reason_counts" =>
        reports
        |> Enum.map(&resource_filter_report_suppressed_reason_counts(&1, callbacks))
        |> merge_count_maps(),
      "candidate_ids_by_suppressed_reason" =>
        reports
        |> Enum.map(&resource_filter_report_candidate_ids_by_suppressed_reason(&1, callbacks))
        |> merge_string_list_maps(),
      "resource_filter_spacecraft_counts" =>
        reports
        |> Enum.map(&resource_filter_report_spacecraft_counts(&1, callbacks))
        |> merge_count_maps(),
      "candidate_ids_by_spacecraft" =>
        reports
        |> Enum.map(&resource_filter_report_candidate_ids_by_spacecraft(&1, callbacks))
        |> merge_string_list_maps(),
      "resource_filter_resource_counts" =>
        reports
        |> Enum.map(&resource_filter_report_resource_counts(&1, callbacks))
        |> merge_count_maps(),
      "candidate_ids_by_resource" =>
        reports
        |> Enum.map(&resource_filter_report_candidate_ids_by_resource(&1, callbacks))
        |> merge_string_list_maps(),
      "resource_filter_blocking_dimension_counts" =>
        reports
        |> Enum.map(&resource_filter_report_blocking_dimension_counts(&1, callbacks))
        |> merge_count_maps(),
      "candidate_ids_by_blocking_dimension" =>
        reports
        |> Enum.map(&resource_filter_report_candidate_ids_by_blocking_dimension(&1, callbacks))
        |> merge_string_list_maps(),
      "direction_counts" => direction_counts,
      "directions" => directions,
      "candidate_ids_by_direction" => candidate_ids_by_direction,
      "direction_routing" =>
        resource_filter_direction_routing(direction_counts, candidate_ids_by_direction),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_resource_filter_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_resource_filter_report_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp row_count(report) do
    suppressed_candidate_count(report) + invalid_resource_summary_input_count(report)
  end

  defp suppressed_candidate_count(report) do
    numeric_report_count(report, "suppressed_candidate_count")
    |> case do
      0 -> length(Map.get(report, "suppressed_candidates", []))
      count -> count
    end
  end

  def invalid_resource_summary_input_count(report) do
    numeric_report_count(report, "invalid_resource_summary_input_count")
    |> case do
      0 -> length(Map.get(report, "invalid_resource_summary_inputs", []))
      count -> count
    end
  end

  defp invalid_resource_summary_input_ids(report, callbacks) do
    explicit_ids =
      report
      |> Map.get("invalid_resource_summary_input_ids")
      |> List.wrap()

    input_ids =
      report
      |> Map.get("invalid_resource_summary_inputs", [])
      |> Enum.map(&stringify_keys(callbacks, &1))
      |> Enum.map(&(&1["resource_summary_id"] || &1["subject_id"]))

    (explicit_ids ++ input_ids)
    |> sorted_string_values()
  end

  defp resource_filter_input_summary_contract(reports) do
    reports
    |> Enum.map(fn report ->
      Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      [] -> nil
      _contracts -> "resource_filter_report.v1"
    end
  end

  defp resource_filter_report_suppressed_reason_counts(report, callbacks) do
    report
    |> Map.get("suppressed_candidates", [])
    |> count_resource_filter_rows("suppressed_reason", callbacks)
    |> case do
      nil -> %{}
      counts -> counts
    end
  end

  defp resource_filter_report_candidate_ids_by_suppressed_reason(report, callbacks) do
    report
    |> resource_filter_report_suppressed_reason_candidate_pairs(callbacks)
    |> case do
      [] ->
        (Map.get(report, "candidate_ids_by_suppressed_reason") ||
           Map.get(report, "suppressed_candidate_ids_by_reason"))
        |> map_value_lists()

      pairs ->
        grouped_source_report_ids(pairs)
    end
  end

  defp resource_filter_report_spacecraft_counts(report, callbacks) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&stringify_keys(callbacks, &1))
    |> Enum.map(&callback!(callbacks, :objective_satisfaction_spacecraft_id).(&1))
    |> count_source_report_values()
  end

  defp resource_filter_report_candidate_ids_by_spacecraft(report, callbacks) do
    report
    |> resource_filter_report_spacecraft_candidate_pairs(callbacks)
    |> case do
      [] ->
        (Map.get(report, "candidate_ids_by_spacecraft") ||
           Map.get(report, "suppressed_candidate_ids_by_spacecraft_id"))
        |> map_value_lists()

      pairs ->
        grouped_source_report_ids(pairs)
    end
  end

  defp resource_filter_report_resource_counts(report, callbacks) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&stringify_keys(callbacks, &1))
    |> Enum.map(&resource_filter_report_row_resource_id(&1, callbacks))
    |> count_source_report_values()
  end

  defp resource_filter_report_candidate_ids_by_resource(report, callbacks) do
    report
    |> resource_filter_report_resource_candidate_pairs(callbacks)
    |> case do
      [] ->
        report
        |> Map.get("candidate_ids_by_resource")
        |> map_value_lists()

      pairs ->
        grouped_source_report_ids(pairs)
    end
  end

  defp resource_filter_report_blocking_dimension_counts(report, callbacks) do
    report
    |> Map.get("suppressed_candidates", [])
    |> count_resource_filter_rows("resource_blocking_dimension", callbacks)
  end

  defp resource_filter_report_candidate_ids_by_blocking_dimension(report, callbacks) do
    report
    |> resource_filter_report_blocking_dimension_candidate_pairs(callbacks)
    |> case do
      [] ->
        (Map.get(report, "candidate_ids_by_blocking_dimension") ||
           Map.get(report, "suppressed_candidate_ids_by_resource_blocking_dimension"))
        |> map_value_lists()

      pairs ->
        grouped_source_report_ids(pairs)
    end
  end

  defp resource_filter_report_direction_counts(report, callbacks) do
    report
    |> resource_filter_report_direction_candidate_pairs(callbacks)
    |> case do
      [] ->
        report
        |> Map.get("direction_counts")
        |> normalize_direction_count_map(callbacks)

      pairs ->
        grouped_source_report_id_counts(pairs)
    end
  end

  defp resource_filter_report_candidate_ids_by_direction(report, callbacks) do
    report
    |> resource_filter_report_direction_candidate_pairs(callbacks)
    |> case do
      [] ->
        report
        |> Map.get("candidate_ids_by_direction")
        |> map_value_lists()

      pairs ->
        grouped_source_report_ids(pairs)
    end
  end

  defp resource_filter_report_direction_keys(direction_counts, candidate_ids_by_direction) do
    [
      resource_filter_map_keys(direction_counts),
      resource_filter_map_keys(candidate_ids_by_direction)
    ]
    |> List.flatten()
    |> sorted_non_empty_values()
  end

  defp resource_filter_direction_routing(direction_counts, candidate_ids_by_direction) do
    direction_counts = direction_counts || %{}
    candidate_ids_by_direction = map_value_lists(candidate_ids_by_direction) || %{}

    [
      resource_filter_map_keys(direction_counts),
      resource_filter_map_keys(candidate_ids_by_direction)
    ]
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn direction ->
      route =
        %{
          "candidate_count" => Map.get(direction_counts, direction),
          "candidate_ids" => Map.get(candidate_ids_by_direction, direction, [])
        }
        |> compact_map()

      {direction, route}
    end)
    |> non_empty_map()
  end

  defp resource_filter_map_keys(%{} = map), do: Map.keys(map)
  defp resource_filter_map_keys(_map), do: []

  defp resource_filter_report_direction_candidate_pairs(report, callbacks) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&stringify_keys(callbacks, &1))
    |> Enum.flat_map(&resource_filter_row_direction_candidate_pairs(&1, callbacks))
  end

  defp resource_filter_report_suppressed_reason_candidate_pairs(report, callbacks) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&stringify_keys(callbacks, &1))
    |> Enum.flat_map(&resource_filter_row_suppressed_reason_candidate_pairs(&1, callbacks))
  end

  defp resource_filter_report_spacecraft_candidate_pairs(report, callbacks) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&stringify_keys(callbacks, &1))
    |> Enum.flat_map(&resource_filter_row_spacecraft_candidate_pairs(&1, callbacks))
  end

  defp resource_filter_report_resource_candidate_pairs(report, callbacks) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&stringify_keys(callbacks, &1))
    |> Enum.flat_map(&resource_filter_row_resource_candidate_pairs(&1, callbacks))
  end

  defp resource_filter_report_blocking_dimension_candidate_pairs(report, callbacks) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&stringify_keys(callbacks, &1))
    |> Enum.flat_map(&resource_filter_row_blocking_dimension_candidate_pairs(&1, callbacks))
  end

  defp resource_filter_row_suppressed_reason_candidate_pairs(row, callbacks) do
    suppressed_reason = normalized_timeline_diff_token(callbacks, row["suppressed_reason"])
    row_candidate_id = resource_filter_row_candidate_id(row, callbacks)

    row
    |> source_contact_values(callbacks)
    |> Kernel.++([row])
    |> Enum.map(fn candidate ->
      {normalized_timeline_diff_token(callbacks, candidate["suppressed_reason"]) ||
         suppressed_reason,
       resource_filter_row_candidate_id(candidate, callbacks) || row_candidate_id}
    end)
    |> Enum.reject(fn {reason, candidate_id} ->
      reason in [nil, ""] or candidate_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp resource_filter_row_spacecraft_candidate_pairs(row, callbacks) do
    spacecraft_id = callback!(callbacks, :objective_satisfaction_spacecraft_id).(row)
    row_candidate_id = resource_filter_row_candidate_id(row, callbacks)

    row
    |> source_contact_values(callbacks)
    |> Kernel.++([row])
    |> Enum.map(fn candidate ->
      {callback!(callbacks, :objective_satisfaction_spacecraft_id).(candidate) || spacecraft_id,
       resource_filter_row_candidate_id(candidate, callbacks) || row_candidate_id}
    end)
    |> reject_empty_resource_filter_candidate_pairs()
  end

  defp resource_filter_row_resource_candidate_pairs(row, callbacks) do
    resource_id = resource_filter_report_row_resource_id(row, callbacks)
    row_candidate_id = resource_filter_row_candidate_id(row, callbacks)

    row
    |> source_contact_values(callbacks)
    |> Kernel.++([row])
    |> Enum.map(fn candidate ->
      {resource_filter_report_row_resource_id(candidate, callbacks) || resource_id,
       resource_filter_row_candidate_id(candidate, callbacks) || row_candidate_id}
    end)
    |> reject_empty_resource_filter_candidate_pairs()
  end

  defp resource_filter_row_blocking_dimension_candidate_pairs(row, callbacks) do
    blocking_dimension =
      normalized_timeline_diff_token(callbacks, row["resource_blocking_dimension"])

    row_candidate_id = resource_filter_row_candidate_id(row, callbacks)

    row
    |> source_contact_values(callbacks)
    |> Kernel.++([row])
    |> Enum.map(fn candidate ->
      {normalized_timeline_diff_token(callbacks, candidate["resource_blocking_dimension"]) ||
         blocking_dimension,
       resource_filter_row_candidate_id(candidate, callbacks) || row_candidate_id}
    end)
    |> reject_empty_resource_filter_candidate_pairs()
  end

  defp reject_empty_resource_filter_candidate_pairs(pairs) do
    pairs
    |> Enum.reject(fn {key, candidate_id} ->
      key in [nil, ""] or candidate_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp resource_filter_row_direction_candidate_pairs(row, callbacks) do
    row_direction = resource_filter_row_direction(row, callbacks)
    row_candidate_id = resource_filter_row_candidate_id(row, callbacks)

    row
    |> source_contact_values(callbacks)
    |> Kernel.++([row])
    |> Enum.map(fn candidate ->
      {resource_filter_row_direction(candidate, callbacks) || row_direction,
       resource_filter_row_candidate_id(candidate, callbacks) || row_candidate_id}
    end)
    |> Enum.reject(fn {direction, candidate_id} ->
      direction in [nil, ""] or candidate_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp resource_filter_row_direction(row, callbacks) do
    [
      row["direction"],
      row["type"],
      row["activity_type"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["activity_context", "type"]),
      get_in(row, ["activity_context", "activity_type"]),
      get_in(row, ["source_activity_context", "direction"]),
      get_in(row, ["source_activity_context", "type"]),
      get_in(row, ["source_activity_context", "activity_type"]),
      get_in(row, ["source_contact_candidate", "direction"]),
      get_in(row, ["source_contact_candidate", "type"]),
      get_in(row, ["source_contact_candidate", "activity_type"]),
      get_in(row, ["contact_candidate", "direction"]),
      get_in(row, ["contact_candidate", "type"]),
      get_in(row, ["contact_candidate", "activity_type"])
    ]
    |> Enum.map(&callback!(callbacks, :normalize_direction).(&1))
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp resource_filter_row_candidate_id(row, callbacks) do
    [
      row["id"],
      row["candidate_id"],
      row["activity_id"],
      row["source_candidate_id"],
      row["source_activity_id"],
      get_in(row, ["activity_context", "id"]),
      get_in(row, ["activity_context", "activity_id"]),
      get_in(row, ["source_activity_context", "id"]),
      get_in(row, ["source_activity_context", "activity_id"]),
      get_in(row, ["source_contact_candidate", "id"]),
      get_in(row, ["source_contact_candidate", "candidate_id"]),
      get_in(row, ["source_contact_candidate", "activity_id"]),
      get_in(row, ["contact_candidate", "id"]),
      get_in(row, ["contact_candidate", "candidate_id"]),
      get_in(row, ["contact_candidate", "activity_id"])
    ]
    |> Enum.map(&callback!(callbacks, :stable_id_or_nil).(&1))
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp resource_filter_report_row_resource_id(row, callbacks) do
    callback!(callbacks, :stable_id_or_nil).(
      row["resource_id"] ||
        row["resource_summary_id"] ||
        row["resource_name"] ||
        row["battery_id"] ||
        row["storage_resource_id"] ||
        row["energy_resource_id"] ||
        row["resource"]
    )
  end

  defp count_resource_filter_rows(rows, field, callbacks) do
    rows
    |> Enum.map(&stringify_keys(callbacks, &1))
    |> Enum.map(&normalized_timeline_diff_token(callbacks, Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp normalize_direction_count_map(%{} = counts, callbacks) do
    counts
    |> Enum.reduce(%{}, fn {direction, count}, acc ->
      case {callback!(callbacks, :normalize_direction).(direction), numeric_value(count)} do
        {nil, _count} -> acc
        {_direction, nil} -> acc
        {direction, count} -> Map.update(acc, direction, trunc(count), &(&1 + trunc(count)))
      end
    end)
    |> non_empty_map()
  end

  defp normalize_direction_count_map(_counts, _callbacks), do: nil

  defp source_contact_values(row, callbacks) do
    callback!(callbacks, :contact_filter_row_source_contact_values).(row)
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp map_value_lists(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_string_values(List.wrap(values)) do
        [] -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  defp map_value_lists(_value), do: nil

  defp grouped_source_report_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_non_empty_values(values)} end)
    |> non_empty_map()
  end

  defp grouped_source_report_id_counts(pairs) do
    pairs
    |> grouped_source_report_ids()
    |> case do
      nil -> nil
      ids_by_key -> Map.new(ids_by_key, fn {key, ids} -> {key, length(ids)} end)
    end
  end

  defp sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp stringify_keys(callbacks, value), do: callback!(callbacks, :stringify_keys).(value)

  defp normalized_timeline_diff_token(callbacks, value),
    do: callback!(callbacks, :normalized_timeline_diff_token).(value)

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
