defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      numeric_report_count: 2,
      sorted_string_values: 1,
      source_report_trust_boundaries: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "contact_contention_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &contact_contention_report_row_count/1),
      "conflict_group_count" =>
        sum_report_count(reports, &contact_contention_report_conflict_group_count/1),
      "invalid_contact_input_count" =>
        sum_report_count(reports, &contact_contention_report_invalid_contact_input_count/1),
      "invalid_contact_input_ids" =>
        reports
        |> Enum.flat_map(&contact_contention_report_invalid_contact_input_ids(&1, callbacks))
        |> sorted_string_values()
        |> case do
          [] -> nil
          ids -> ids
        end,
      "resource_scope_counts" =>
        reports
        |> Enum.map(&contact_contention_report_resource_scope_counts/1)
        |> merge_count_maps(),
      "contact_contention_ground_station_counts" =>
        reports
        |> Enum.map(&contact_contention_report_ground_station_counts(&1, callbacks))
        |> merge_count_maps(),
      "contact_contention_contact_id_counts" =>
        reports
        |> Enum.map(&contact_contention_report_contact_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "direction_counts" =>
        reports
        |> Enum.map(&contact_contention_report_direction_counts(&1, callbacks))
        |> merge_count_maps(),
      "contact_ids_by_direction" =>
        reports
        |> Enum.map(&contact_contention_report_contact_ids_by_direction(&1, callbacks))
        |> merge_string_list_maps(),
      "direction_routing" => contact_contention_direction_routing(reports, callbacks),
      "required_operator_action_counts" =>
        reports
        |> Enum.map(&contact_contention_report_required_action_counts/1)
        |> merge_count_maps(),
      "trust_boundary_status" => source_contact_contention_report_trust_boundary_status(reports),
      "trust_boundaries" => source_contact_contention_report_trust_boundaries(reports)
    }
    |> compact_map()
  end

  defp contact_contention_report_row_count(report) do
    contact_contention_report_conflict_group_count(report) +
      contact_contention_report_invalid_contact_input_count(report)
  end

  defp contact_contention_report_conflict_group_count(report) do
    numeric_report_count(report, "conflict_group_count")
    |> case do
      0 -> length(Map.get(report, "conflict_groups", []))
      count -> count
    end
  end

  defp contact_contention_report_invalid_contact_input_count(report) do
    numeric_report_count(report, "invalid_contact_input_count")
    |> case do
      0 -> length(Map.get(report, "invalid_contact_inputs", []))
      count -> count
    end
  end

  defp contact_contention_report_invalid_contact_input_ids(report, callbacks) do
    explicit_ids =
      report
      |> Map.get("invalid_contact_input_ids")
      |> List.wrap()

    row_ids =
      report
      |> Map.get("invalid_contact_inputs", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(
        &callback!(callbacks, :stable_id_or_nil).(
          &1["contact_id"] || &1["id"] || &1["subject_id"]
        )
      )

    (explicit_ids ++ row_ids)
    |> sorted_string_values()
  end

  defp contact_contention_report_resource_scope_counts(report) do
    report
    |> Map.get("conflict_groups", [])
    |> count_contact_contention_rows("resource_scope")
    |> case do
      nil -> %{}
      counts -> counts
    end
  end

  defp contact_contention_report_ground_station_counts(report, callbacks) do
    stable_id_or_nil = callback!(callbacks, :stable_id_or_nil)

    report
    |> Map.get("conflict_groups", [])
    |> Enum.map(&stable_id_or_nil.(Map.get(&1, "ground_station_id")))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> non_empty_map()
  end

  defp contact_contention_report_contact_id_counts(report, callbacks) do
    stable_id_or_nil = callback!(callbacks, :stable_id_or_nil)

    report
    |> Map.get("conflict_groups", [])
    |> Enum.flat_map(fn group ->
      group
      |> Map.get("contact_ids", [])
      |> List.wrap()
    end)
    |> Enum.map(stable_id_or_nil)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> non_empty_map()
  end

  defp contact_contention_report_direction_counts(report, callbacks) do
    report
    |> contact_contention_report_direction_contact_pairs(callbacks)
    |> case do
      [] ->
        report
        |> Map.get("direction_counts")
        |> normalize_direction_count_map(callbacks)

      pairs ->
        grouped_source_report_id_counts(pairs)
    end
  end

  defp contact_contention_report_contact_ids_by_direction(report, callbacks) do
    report
    |> contact_contention_report_direction_contact_pairs(callbacks)
    |> case do
      [] ->
        report
        |> Map.get("contact_ids_by_direction")
        |> map_value_lists()

      pairs ->
        grouped_source_report_ids(pairs)
    end
  end

  defp contact_contention_direction_routing(reports, callbacks) do
    direction_counts =
      reports
      |> Enum.map(&contact_contention_report_direction_counts(&1, callbacks))
      |> merge_count_maps()
      |> empty_map_if_nil()

    contact_ids_by_direction =
      reports
      |> Enum.map(&contact_contention_report_contact_ids_by_direction(&1, callbacks))
      |> merge_string_list_maps()
      |> empty_map_if_nil()

    [
      Map.keys(direction_counts),
      Map.keys(contact_ids_by_direction)
    ]
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn direction ->
      route =
        %{
          "contact_count" => Map.get(direction_counts, direction),
          "contact_ids" => Map.get(contact_ids_by_direction, direction, [])
        }
        |> compact_map()

      {direction, route}
    end)
    |> non_empty_map()
  end

  defp contact_contention_report_direction_contact_pairs(report, callbacks) do
    report
    |> Map.get("conflict_groups", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(&contact_contention_group_direction_contact_pairs(&1, callbacks))
  end

  defp contact_contention_group_direction_contact_pairs(group, callbacks) do
    source_contacts =
      group
      |> Map.get("source_contact_candidates", [])
      |> List.wrap()
      |> List.flatten()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    case source_contacts do
      [] ->
        contact_contention_group_fallback_direction_contact_pairs(group, callbacks)

      contacts ->
        Enum.map(contacts, &contact_contention_contact_direction_pair(&1, group, callbacks))
    end
    |> Enum.reject(fn {direction, contact_id} ->
      direction in [nil, ""] or contact_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp contact_contention_group_fallback_direction_contact_pairs(group, callbacks) do
    directions = contact_contention_group_directions(group, callbacks)
    stable_id_or_nil = callback!(callbacks, :stable_id_or_nil)

    contact_ids =
      group
      |> Map.get("contact_ids", [])
      |> List.wrap()
      |> List.flatten()
      |> Enum.map(stable_id_or_nil)
      |> Enum.reject(&is_nil/1)

    for direction <- directions, contact_id <- contact_ids, do: {direction, contact_id}
  end

  defp contact_contention_contact_direction_pair(contact, group, callbacks) do
    normalize_direction = callback!(callbacks, :normalize_direction)
    stable_id_or_nil = callback!(callbacks, :stable_id_or_nil)

    direction =
      [
        contact["direction"],
        contact["type"],
        get_in(contact, ["activity_context", "direction"]),
        group["direction"]
      ]
      |> Enum.map(normalize_direction)
      |> Enum.find(&(&1 not in [nil, "", "mixed", "contact"]))

    contact_id =
      [
        contact["contact_id"],
        contact["id"],
        contact["activity_id"],
        get_in(contact, ["activity_context", "contact_id"]),
        get_in(contact, ["activity_context", "id"])
      ]
      |> Enum.map(stable_id_or_nil)
      |> Enum.find(&(&1 not in [nil, ""]))

    {direction, contact_id}
  end

  defp contact_contention_group_directions(group, callbacks) do
    normalize_direction = callback!(callbacks, :normalize_direction)

    [
      group["directions"],
      group["direction"]
    ]
    |> List.flatten()
    |> Enum.map(normalize_direction)
    |> Enum.reject(&(&1 in [nil, "", "mixed", "contact"]))
    |> Enum.uniq()
  end

  defp contact_contention_report_required_action_counts(report) do
    groups =
      report
      |> Map.get("conflict_groups", [])
      |> count_contact_contention_rows("required_operator_action")

    invalid_inputs =
      report
      |> Map.get("invalid_contact_inputs", [])
      |> count_contact_contention_rows("required_operator_action")

    [groups, invalid_inputs]
    |> merge_count_maps()
    |> case do
      nil -> %{}
      counts -> counts
    end
  end

  defp source_contact_contention_report_trust_boundary_status(reports) do
    case source_contact_contention_report_trust_boundaries(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp source_contact_contention_report_trust_boundaries(reports) do
    reports
    |> source_report_trust_boundaries()
    |> Kernel.++(
      reports
      |> Enum.flat_map(fn report ->
        (Map.get(report, "conflict_groups", []) ++ Map.get(report, "invalid_contact_inputs", []))
        |> source_report_trust_boundaries()
      end)
    )
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp count_contact_contention_rows(rows, field) do
    rows
    |> Enum.map(&normalized_timeline_diff_token(Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp normalize_direction_count_map(%{} = counts, callbacks) do
    normalize_direction = callback!(callbacks, :normalize_direction)

    counts
    |> Enum.reduce(%{}, fn {direction, count}, acc ->
      case {normalize_direction.(direction), numeric_value(count)} do
        {nil, _count} -> acc
        {_direction, nil} -> acc
        {direction, count} -> Map.update(acc, direction, trunc(count), &(&1 + trunc(count)))
      end
    end)
    |> non_empty_map()
  end

  defp normalize_direction_count_map(_counts, _callbacks), do: nil

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

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}

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

  defp normalized_timeline_diff_token(value) do
    value
    |> encode_value()
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> String.trim("_")
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

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
