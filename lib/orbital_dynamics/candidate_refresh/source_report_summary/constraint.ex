defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_source_report_values: 1,
      merge_count_maps: 1,
      normalize_trust_boundaries: 1,
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
      "contract" => "constraint_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &constraint_report_row_count/1),
      "downlink_gap_row_count" =>
        sum_report_count(reports, &constraint_report_downlink_gap_row_count(&1, callbacks)),
      "resource_margin_row_count" =>
        sum_report_count(reports, &constraint_report_resource_margin_row_count(&1, callbacks)),
      "status_counts" =>
        reports
        |> Enum.map(&constraint_report_status_counts/1)
        |> merge_count_maps(),
      "ground_station_counts" =>
        reports
        |> Enum.map(&constraint_report_ground_station_counts(&1, callbacks))
        |> merge_count_maps(),
      "constraint_metric_counts" =>
        reports
        |> Enum.map(&constraint_report_metric_counts(&1, callbacks))
        |> merge_count_maps(),
      "constraint_id_counts" =>
        reports
        |> Enum.map(&constraint_report_constraint_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "source_activity_id_counts" =>
        reports
        |> Enum.map(&constraint_report_source_activity_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "constraint_resource_counts" =>
        reports
        |> Enum.map(&constraint_report_resource_counts(&1, callbacks))
        |> merge_count_maps(),
      "constraint_spacecraft_counts" =>
        reports
        |> Enum.map(&constraint_report_spacecraft_counts(&1, callbacks))
        |> merge_count_maps(),
      "trust_boundary_status" =>
        source_constraint_report_trust_boundary_status(reports, callbacks),
      "trust_boundaries" => source_constraint_report_trust_boundaries(reports, callbacks)
    }
    |> compact_map()
  end

  defp constraint_report_row_count(report), do: length(Map.get(report, "rows", []))

  defp constraint_report_downlink_gap_row_count(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(callback!(callbacks, :constraint_downlink_gap))
  end

  defp constraint_report_resource_margin_row_count(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(callback!(callbacks, :constraint_resource_margin_gap))
  end

  defp constraint_report_status_counts(report) do
    report
    |> Map.get("rows", [])
    |> count_constraint_rows("status")
  end

  defp constraint_report_ground_station_counts(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(callback!(callbacks, :constraint_station_id))
    |> count_source_report_values()
  end

  defp constraint_report_metric_counts(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(callback!(callbacks, :constraint_metric))
    |> count_source_report_values()
  end

  defp constraint_report_constraint_id_counts(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(callback!(callbacks, :constraint_id))
    |> count_source_report_values()
  end

  defp constraint_report_source_activity_id_counts(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(&(callback!(callbacks, :constraint_source_activity_ids).(&1) || []))
    |> count_source_report_values()
  end

  defp constraint_report_resource_counts(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(callback!(callbacks, :constraint_resource_id))
    |> count_source_report_values()
  end

  defp constraint_report_spacecraft_counts(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(callback!(callbacks, :constraint_spacecraft_id))
    |> count_source_report_values()
  end

  defp source_constraint_report_trust_boundary_status(reports, callbacks) do
    case source_constraint_report_trust_boundaries(reports, callbacks) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp source_constraint_report_trust_boundaries(reports, callbacks) when is_list(reports) do
    reports
    |> Enum.flat_map(&source_constraint_report_trust_boundaries(&1, callbacks))
    |> normalize_trust_boundaries()
  end

  defp source_constraint_report_trust_boundaries(%{"rows" => rows} = report, callbacks)
       when is_list(rows) do
    row_trust_boundaries =
      rows
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(
        &Map.put_new(
          &1,
          "_source_report_trust_boundary",
          callback!(callbacks, :result_artifact_trust_boundary).(report)
        )
      )
      |> Enum.map(callback!(callbacks, :constraint_trust_boundary))

    row_trust_boundaries ++ source_report_trust_boundaries([report])
  end

  defp source_constraint_report_trust_boundaries(%{} = report, _callbacks),
    do: source_report_trust_boundaries([report])

  defp count_constraint_rows(rows, field) do
    rows
    |> Enum.map(&normalized_timeline_diff_token(Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
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
