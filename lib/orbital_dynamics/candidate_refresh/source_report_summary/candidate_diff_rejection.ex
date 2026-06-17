defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_source_report_values: 1,
      merge_count_maps: 1,
      normalize_trust_boundaries: 1,
      numeric_report_count: 2,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1,
      sum_report_count: 2
    ]

  def candidate_diff_report_input_summary([], _callbacks), do: nil

  def candidate_diff_report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    count_reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "candidate_diff_report.v1",
      "count" => length(count_reports),
      "row_count" => sum_report_count(count_reports, &candidate_diff_report_row_count/1),
      "retained_candidate_count" =>
        sum_report_count(count_reports, &candidate_diff_report_retained_count/1),
      "new_candidate_count" =>
        sum_report_count(count_reports, &candidate_diff_report_new_count/1),
      "invalidated_candidate_count" =>
        sum_report_count(count_reports, &candidate_diff_report_invalidated_count/1),
      "diff_reason_counts" =>
        count_reports
        |> Enum.map(&candidate_diff_report_diff_reason_counts/1)
        |> merge_count_maps(),
      "invalidated_reason_counts" =>
        count_reports
        |> Enum.map(&candidate_diff_report_invalidated_reason_counts/1)
        |> merge_count_maps(),
      "semantic_change_reason_counts" =>
        count_reports
        |> Enum.map(&candidate_diff_report_semantic_change_reason_counts/1)
        |> merge_count_maps(),
      "candidate_diff_changed_field_counts" =>
        count_reports
        |> Enum.map(&candidate_diff_report_changed_field_counts/1)
        |> merge_count_maps(),
      "candidate_diff_candidate_id_counts" =>
        count_reports
        |> Enum.map(&candidate_diff_report_candidate_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "candidate_diff_ground_station_counts" =>
        count_reports
        |> Enum.map(&candidate_diff_report_ground_station_counts(&1, callbacks))
        |> merge_count_maps(),
      "trust_boundary_status" => source_report_trust_boundary_status(count_reports),
      "trust_boundaries" => source_candidate_diff_report_trust_boundaries(count_reports)
    }
    |> compact_map()
  end

  def candidate_rejection_report_input_summary([], _callbacks), do: nil

  def candidate_rejection_report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "candidate_rejection_report.v1",
      "count" => length(sources),
      "row_count" =>
        sum_report_count(reports, &candidate_rejection_report_row_count(&1, callbacks)),
      "rejected_count" => sum_report_count(reports, &numeric_report_count(&1, "rejected_count")),
      "reviewable_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "reviewable_count")),
      "invalid_candidate_input_count" =>
        sum_report_count(
          reports,
          &numeric_report_count(&1, "invalid_candidate_input_count")
        ),
      "rejection_reason_counts" =>
        reports
        |> Enum.map(&candidate_rejection_report_rejection_reason_counts/1)
        |> merge_count_maps(),
      "required_operator_action_counts" =>
        reports
        |> Enum.map(&candidate_rejection_report_required_action_counts/1)
        |> merge_count_maps(),
      "candidate_rejection_candidate_id_counts" =>
        reports
        |> Enum.map(&candidate_rejection_report_candidate_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "candidate_rejection_ground_station_counts" =>
        reports
        |> Enum.map(&candidate_rejection_report_ground_station_counts(&1, callbacks))
        |> merge_count_maps(),
      "trust_boundary_status" => source_candidate_rejection_report_trust_boundary_status(reports),
      "trust_boundaries" => source_candidate_rejection_report_trust_boundaries(reports)
    }
    |> compact_map()
  end

  defp candidate_diff_report_row_count(report) do
    candidate_diff_report_retained_count(report) +
      candidate_diff_report_new_count(report) +
      candidate_diff_report_invalidated_count(report)
  end

  defp candidate_diff_report_retained_count(report),
    do: length(Map.get(report, "retained_candidates", []))

  defp candidate_diff_report_new_count(report), do: length(Map.get(report, "new_candidates", []))

  defp candidate_diff_report_invalidated_count(report),
    do: length(Map.get(report, "invalidated_candidates", []))

  defp candidate_diff_report_diff_reason_counts(report) do
    report
    |> candidate_diff_report_rows()
    |> count_source_report_rows("diff_reason")
  end

  defp candidate_diff_report_invalidated_reason_counts(report) do
    report
    |> candidate_diff_report_rows()
    |> count_source_report_rows("invalidated_reason")
  end

  defp candidate_diff_report_semantic_change_reason_counts(report) do
    report
    |> candidate_diff_report_rows()
    |> Enum.flat_map(&(Map.get(&1, "semantic_change_reasons") |> list_value()))
    |> count_source_report_values()
  end

  defp candidate_diff_report_changed_field_counts(report) do
    report
    |> candidate_diff_report_rows()
    |> Enum.flat_map(&(Map.get(&1, "candidate_diff_changed_fields") |> list_value()))
    |> count_source_report_values()
  end

  defp candidate_diff_report_candidate_id_counts(report, callbacks) do
    report
    |> candidate_diff_report_rows()
    |> Enum.map(&candidate_diff_row_candidate_id(&1, callbacks))
    |> count_source_report_values()
  end

  defp candidate_diff_report_ground_station_counts(report, callbacks) do
    report
    |> candidate_diff_report_rows()
    |> Enum.map(&candidate_diff_row_ground_station_id(&1, callbacks))
    |> count_source_report_values()
  end

  defp candidate_diff_row_candidate_id(%{} = row, callbacks) do
    callback!(callbacks, :stable_id_or_nil).(
      Map.get(row, "candidate_id") ||
        Map.get(row, "id") ||
        Map.get(row, "activity_id") ||
        get_in(row, ["activity_context", "activity_id"])
    )
  end

  defp candidate_diff_row_candidate_id(_row, _callbacks), do: nil

  defp candidate_diff_row_ground_station_id(%{} = row, callbacks) do
    callback!(callbacks, :stable_id_or_nil).(
      Map.get(row, "ground_station_id") ||
        Map.get(row, "station_id") ||
        callback!(callbacks, :nested_station_id).(row) ||
        get_in(row, ["source_window", "ground_station_id"]) ||
        get_in(row, ["source_window", "station_id"]) ||
        get_in(row, ["activity_context", "ground_station_id"])
    )
  end

  defp candidate_diff_row_ground_station_id(_row, _callbacks), do: nil

  defp candidate_rejection_report_row_count(report, callbacks) do
    case numeric_report_count(report, "row_count") do
      0 -> callback!(callbacks, :report_rows_count).(report)
      count -> count
    end
  end

  defp candidate_rejection_report_rejection_reason_counts(report) do
    case candidate_rejection_report_rows(report) do
      [] ->
        Map.get(report, "rejection_reason_counts")

      rows ->
        rows
        |> Enum.flat_map(&candidate_rejection_row_reasons/1)
        |> count_source_report_values()
    end
  end

  defp candidate_rejection_report_required_action_counts(report) do
    case candidate_rejection_report_rows(report) do
      [] ->
        Map.get(report, "required_operator_action_counts")

      rows ->
        count_source_report_rows(rows, "required_operator_action")
    end
  end

  defp candidate_rejection_report_candidate_id_counts(report, callbacks) do
    stable_id_or_nil = callback!(callbacks, :stable_id_or_nil)

    report
    |> candidate_rejection_report_rows()
    |> Enum.map(&stable_id_or_nil.(Map.get(&1, "candidate_id")))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> non_empty_map()
  end

  defp candidate_rejection_report_ground_station_counts(report, callbacks) do
    report
    |> candidate_rejection_report_rows()
    |> Enum.map(&candidate_rejection_row_ground_station_id(&1, callbacks))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> non_empty_map()
  end

  defp candidate_rejection_report_rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
  end

  defp candidate_rejection_row_reasons(row) do
    row
    |> Map.get("rejection_reasons")
    |> list_value()
    |> case do
      [] -> List.wrap(Map.get(row, "primary_rejection_reason"))
      reasons -> reasons
    end
  end

  defp candidate_rejection_row_ground_station_id(%{} = row, callbacks) do
    stable_id_or_nil = callback!(callbacks, :stable_id_or_nil)

    [
      Map.get(row, "ground_station_id"),
      get_in(row, ["activity_context", "ground_station_id"])
    ]
    |> Enum.find_value(stable_id_or_nil)
  end

  defp candidate_rejection_row_ground_station_id(_row, _callbacks), do: nil

  defp source_candidate_diff_report_trust_boundaries(reports) do
    reports
    |> source_report_trust_boundaries()
    |> Kernel.++(
      reports
      |> Enum.flat_map(fn report ->
        report
        |> candidate_diff_report_rows()
        |> Enum.flat_map(fn row ->
          row = stringify_keys(row)

          [
            row["trust_boundary"],
            row["source_trust_boundary"],
            get_in(row, ["provenance", "trust_boundary"]),
            get_in(row, ["source_window", "provenance", "trust_boundary"])
          ]
        end)
      end)
    )
    |> normalize_trust_boundaries()
  end

  defp source_candidate_rejection_report_trust_boundary_status(reports) do
    case source_candidate_rejection_report_trust_boundaries(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp source_candidate_rejection_report_trust_boundaries(reports) do
    reports
    |> source_report_trust_boundaries()
    |> Kernel.++(
      reports
      |> Enum.flat_map(fn report ->
        report
        |> Map.get("rows", [])
        |> Enum.flat_map(fn row ->
          row = stringify_keys(row)

          [
            row["trust_boundary"],
            row["source_trust_boundary"],
            get_in(row, ["provenance", "trust_boundary"]),
            get_in(row, ["activity_context", "provenance", "trust_boundary"])
          ]
        end)
      end)
    )
    |> normalize_trust_boundaries()
  end

  defp candidate_diff_report_rows(report) do
    Map.get(report, "retained_candidates", []) ++
      Map.get(report, "new_candidates", []) ++
      Map.get(report, "invalidated_candidates", [])
  end

  defp count_source_report_rows(rows, field) do
    rows
    |> Enum.map(&(Map.get(&1, field) |> normalized_timeline_diff_token()))
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

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

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
