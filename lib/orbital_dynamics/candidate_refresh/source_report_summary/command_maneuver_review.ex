defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_source_report_values: 1,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def command_window_report_input_summary([], _callbacks), do: nil

  def command_window_report_input_summary(sources, callbacks) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "command_window_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, callback!(callbacks, :report_rows_count)),
      "command_feedback_count" =>
        sum_report_count(reports, &command_window_report_command_feedback_count(&1, callbacks)),
      "input_keys" =>
        callback!(callbacks, :source_report_feedback_input_keys).(
          reports,
          callback!(callbacks, :command_window_report_operational_feedback)
        ),
      "direction_counts" =>
        reports
        |> Enum.map(&command_window_report_direction_counts(&1, callbacks))
        |> merge_count_maps(),
      "activity_ids_by_direction" =>
        reports
        |> Enum.map(&command_window_report_activity_ids_by_direction(&1, callbacks))
        |> merge_string_list_maps(),
      "window_ids_by_direction" =>
        reports
        |> Enum.map(&command_window_report_window_ids_by_direction(&1, callbacks))
        |> merge_string_list_maps(),
      "direction_routing" => command_window_direction_routing(reports, callbacks),
      "required_operator_action_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :command_window_report_source_required_operator_action_counts)
        )
        |> merge_count_maps(),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_command_window_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_command_window_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  def maneuver_review_report_input_summary([], _callbacks), do: nil

  def maneuver_review_report_input_summary(sources, callbacks) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "maneuver_review_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, callback!(callbacks, :report_rows_count)),
      "maneuver_success_feedback_count" =>
        sum_report_count(reports, &maneuver_review_report_success_feedback_count(&1, callbacks)),
      "execution_uncertainty_declared_count" =>
        sum_report_count(
          reports,
          &maneuver_review_report_execution_uncertainty_declared_count(&1, callbacks)
        ),
      "execution_uncertainty_missing_count" =>
        sum_report_count(
          reports,
          &maneuver_review_report_execution_uncertainty_missing_count(&1, callbacks)
        ),
      "input_keys" =>
        callback!(callbacks, :source_report_feedback_input_keys).(
          reports,
          callback!(callbacks, :maneuver_review_report_operational_feedback)
        ),
      "maneuver_id_counts" =>
        reports
        |> Enum.map(&maneuver_review_report_maneuver_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "required_operator_action_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :maneuver_review_report_source_required_operator_action_counts)
        )
        |> merge_count_maps(),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_maneuver_review_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_maneuver_review_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp command_window_report_command_feedback_count(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(callback!(callbacks, :command_window_feedback_row))
  end

  defp command_window_report_direction_counts(report, callbacks) do
    report
    |> command_window_report_direction_identifier_pairs(callbacks)
    |> case do
      [] ->
        report
        |> Map.get("direction_counts")
        |> normalize_direction_count_map(callbacks)

      pairs ->
        grouped_source_report_id_counts(pairs)
    end
  end

  defp command_window_report_activity_ids_by_direction(report, callbacks) do
    report
    |> command_window_report_direction_activity_pairs(callbacks)
    |> case do
      [] ->
        report
        |> Map.get("activity_ids_by_direction")
        |> map_value_lists()

      pairs ->
        grouped_source_report_ids(pairs)
    end
  end

  defp command_window_report_window_ids_by_direction(report, callbacks) do
    report
    |> command_window_report_direction_window_pairs(callbacks)
    |> case do
      [] ->
        report
        |> Map.get("window_ids_by_direction")
        |> map_value_lists()

      pairs ->
        grouped_source_report_ids(pairs)
    end
  end

  defp command_window_direction_routing(reports, callbacks) do
    direction_counts =
      reports
      |> Enum.map(&command_window_report_direction_counts(&1, callbacks))
      |> merge_count_maps()
      |> empty_map_if_nil()

    activity_ids_by_direction =
      reports
      |> Enum.map(&command_window_report_activity_ids_by_direction(&1, callbacks))
      |> merge_string_list_maps()
      |> empty_map_if_nil()

    window_ids_by_direction =
      reports
      |> Enum.map(&command_window_report_window_ids_by_direction(&1, callbacks))
      |> merge_string_list_maps()
      |> empty_map_if_nil()

    [
      Map.keys(direction_counts),
      Map.keys(activity_ids_by_direction),
      Map.keys(window_ids_by_direction)
    ]
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn direction ->
      route =
        %{
          "activity_count" => Map.get(direction_counts, direction),
          "activity_ids" => Map.get(activity_ids_by_direction, direction, []),
          "window_ids" => Map.get(window_ids_by_direction, direction, [])
        }
        |> compact_map()

      {direction, route}
    end)
    |> non_empty_map()
  end

  defp command_window_report_direction_identifier_pairs(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      {command_window_row_direction(row, callbacks),
       command_window_row_activity_id(row, callbacks) ||
         command_window_row_window_id(row, callbacks)}
    end)
    |> Enum.reject(fn {direction, identifier} ->
      direction in [nil, ""] or identifier in [nil, ""]
    end)
  end

  defp command_window_report_direction_activity_pairs(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      {command_window_row_direction(row, callbacks),
       command_window_row_activity_id(row, callbacks)}
    end)
    |> Enum.reject(fn {direction, activity_id} ->
      direction in [nil, ""] or activity_id in [nil, ""]
    end)
  end

  defp command_window_report_direction_window_pairs(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      {command_window_row_direction(row, callbacks), command_window_row_window_id(row, callbacks)}
    end)
    |> Enum.reject(fn {direction, window_id} ->
      direction in [nil, ""] or window_id in [nil, ""]
    end)
  end

  defp command_window_row_direction(row, callbacks) do
    normalize_direction = callback!(callbacks, :normalize_direction)

    [
      row["direction"],
      command_window_type_direction(row["window_type"]),
      row["activity_type"],
      row["type"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["source_activity", "direction"]),
      get_in(row, ["source_activity", "activity_context", "direction"])
    ]
    |> Enum.map(normalize_direction)
    |> Enum.find(&(&1 not in [nil, "", "contact"]))
  end

  defp command_window_type_direction("command_window"), do: "command"
  defp command_window_type_direction("uplink_window"), do: "uplink"
  defp command_window_type_direction("tracking_window"), do: "tracking"
  defp command_window_type_direction("health_check_window"), do: "health_check"
  defp command_window_type_direction(_window_type), do: nil

  defp command_window_row_activity_id(row, callbacks) do
    stable_id_or_nil = callback!(callbacks, :stable_id_or_nil)

    [
      row["activity_id"],
      row["source_activity_id"],
      get_in(row, ["activity_context", "activity_id"]),
      get_in(row, ["activity_context", "id"]),
      get_in(row, ["source_activity", "id"]),
      get_in(row, ["source_activity", "activity_id"])
    ]
    |> Enum.map(stable_id_or_nil)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp command_window_row_window_id(row, callbacks) do
    stable_id_or_nil = callback!(callbacks, :stable_id_or_nil)

    [
      row["command_window_id"],
      row["id"],
      get_in(row, ["activity_context", "command_window_id"]),
      get_in(row, ["source_activity_context", "command_window_id"]),
      get_in(row, ["source_activity", "command_window_id"]),
      get_in(row, ["source_activity", "activity_context", "command_window_id"])
    ]
    |> Enum.map(stable_id_or_nil)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp maneuver_review_report_success_feedback_count(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(callback!(callbacks, :maneuver_review_success_feedback_row))
  end

  defp maneuver_review_report_execution_uncertainty_declared_count(report, callbacks) do
    execution_uncertainty_status =
      callback!(callbacks, :maneuver_review_execution_uncertainty_status)

    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(&(execution_uncertainty_status.(&1) == "declared"))
  end

  defp maneuver_review_report_execution_uncertainty_missing_count(report, callbacks) do
    execution_uncertainty_status =
      callback!(callbacks, :maneuver_review_execution_uncertainty_status)

    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(&(execution_uncertainty_status.(&1) == "missing"))
  end

  defp maneuver_review_report_maneuver_id_counts(report, callbacks) do
    case Map.get(report, "rows", []) do
      [] ->
        Map.get(report, "maneuver_id_counts")

      rows ->
        rows
        |> Enum.map(&stringify_keys/1)
        |> Enum.map(callback!(callbacks, :maneuver_review_feedback_key))
        |> count_source_report_values()
    end
  end

  defp trust_boundary_status(reports, trust_boundaries_fun) do
    case trust_boundaries_fun.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
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
