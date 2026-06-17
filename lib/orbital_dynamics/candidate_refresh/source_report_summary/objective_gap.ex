defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap do
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

  def objective_satisfaction_report_input_summary([], _callbacks), do: nil

  def objective_satisfaction_report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "objective_satisfaction_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &objective_satisfaction_report_row_count/1),
      "gap_row_count" =>
        sum_report_count(reports, &objective_satisfaction_report_gap_row_count(&1, callbacks)),
      "downlink_gap_row_count" =>
        sum_report_count(
          reports,
          &objective_satisfaction_report_downlink_gap_row_count(&1, callbacks)
        ),
      "target_gap_row_count" =>
        sum_report_count(
          reports,
          &objective_satisfaction_report_target_gap_row_count(&1, callbacks)
        ),
      "collection_latency_gap_row_count" =>
        sum_report_count(
          reports,
          &objective_satisfaction_report_collection_latency_gap_row_count(&1, callbacks)
        ),
      "status_counts" =>
        reports
        |> Enum.map(&objective_satisfaction_report_status_counts(&1, callbacks))
        |> merge_count_maps(),
      "objective_type_counts" =>
        reports
        |> Enum.map(&objective_satisfaction_report_objective_type_counts(&1, callbacks))
        |> merge_count_maps(),
      "ground_station_counts" =>
        reports
        |> Enum.map(&objective_satisfaction_report_ground_station_counts(&1, callbacks))
        |> merge_count_maps(),
      "target_counts" =>
        reports
        |> Enum.map(&objective_satisfaction_report_target_counts(&1, callbacks))
        |> merge_count_maps(),
      "collection_counts" =>
        reports
        |> Enum.map(&objective_satisfaction_report_collection_counts(&1, callbacks))
        |> merge_count_maps(),
      "source_activity_id_counts" =>
        reports
        |> Enum.map(&objective_satisfaction_report_source_activity_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "trust_boundary_status" =>
        source_objective_satisfaction_report_trust_boundary_status(reports, callbacks),
      "trust_boundaries" =>
        source_objective_satisfaction_report_trust_boundaries(reports, callbacks)
    }
    |> compact_map()
  end

  def objective_tradeoff_report_input_summary([], _callbacks), do: nil

  def objective_tradeoff_report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "objective_tradeoff_report.v1",
      "count" => length(sources),
      "row_count" =>
        sum_report_count(reports, &objective_tradeoff_report_row_count(&1, callbacks)),
      "downlink_gap_row_count" =>
        sum_report_count(
          reports,
          &objective_tradeoff_report_downlink_gap_row_count(&1, callbacks)
        ),
      "target_gap_row_count" =>
        sum_report_count(reports, &objective_tradeoff_report_target_gap_row_count(&1, callbacks)),
      "collection_latency_gap_row_count" =>
        sum_report_count(
          reports,
          &objective_tradeoff_report_collection_latency_gap_row_count(&1, callbacks)
        ),
      "ground_station_counts" =>
        reports
        |> Enum.map(&objective_tradeoff_report_ground_station_counts(&1, callbacks))
        |> merge_count_maps(),
      "target_counts" =>
        reports
        |> Enum.map(&objective_tradeoff_report_target_counts(&1, callbacks))
        |> merge_count_maps(),
      "collection_counts" =>
        reports
        |> Enum.map(&objective_tradeoff_report_collection_counts(&1, callbacks))
        |> merge_count_maps(),
      "source_activity_id_counts" =>
        reports
        |> Enum.map(&objective_tradeoff_report_source_activity_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "trust_boundary_status" =>
        source_objective_tradeoff_report_trust_boundary_status(reports, callbacks),
      "trust_boundaries" => source_objective_tradeoff_report_trust_boundaries(reports, callbacks)
    }
    |> compact_map()
  end

  def score_term_report_input_summary([], _callbacks), do: nil

  def score_term_report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "score_term_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &score_term_report_row_count/1),
      "downlink_gap_row_count" =>
        sum_report_count(reports, &score_term_report_downlink_gap_row_count(&1, callbacks)),
      "target_gap_row_count" =>
        sum_report_count(reports, &score_term_report_target_gap_row_count(&1, callbacks)),
      "collection_latency_gap_row_count" =>
        sum_report_count(
          reports,
          &score_term_report_collection_latency_gap_row_count(&1, callbacks)
        ),
      "term_key_counts" =>
        reports
        |> Enum.map(&score_term_report_term_key_counts(&1, callbacks))
        |> merge_count_maps(),
      "ground_station_counts" =>
        reports
        |> Enum.map(&score_term_report_ground_station_counts(&1, callbacks))
        |> merge_count_maps(),
      "target_counts" =>
        reports
        |> Enum.map(&score_term_report_target_counts(&1, callbacks))
        |> merge_count_maps(),
      "collection_counts" =>
        reports
        |> Enum.map(&score_term_report_collection_counts(&1, callbacks))
        |> merge_count_maps(),
      "source_activity_id_counts" =>
        reports
        |> Enum.map(&score_term_report_source_activity_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "trust_boundary_status" =>
        source_score_term_report_trust_boundary_status(reports, callbacks),
      "trust_boundaries" => source_score_term_report_trust_boundaries(reports, callbacks)
    }
    |> compact_map()
  end

  defp objective_satisfaction_report_row_count(report), do: length(Map.get(report, "rows", []))

  defp objective_satisfaction_report_gap_row_count(report, callbacks) do
    report
    |> objective_satisfaction_report_rows(callbacks)
    |> Enum.count(&callback!(callbacks, :objective_satisfaction_gap_status).(&1["status"]))
  end

  defp objective_satisfaction_report_downlink_gap_row_count(report, callbacks) do
    report
    |> objective_satisfaction_report_rows(callbacks)
    |> Enum.count(fn row ->
      callback!(callbacks, :objective_satisfaction_gap_status).(row["status"]) and
        callback!(callbacks, :objective_satisfaction_objective_type).(row) in [
          "downlink_completion",
          "required_downlink_completion"
        ]
    end)
  end

  defp objective_satisfaction_report_target_gap_row_count(report, callbacks) do
    report
    |> objective_satisfaction_report_rows(callbacks)
    |> Enum.count(fn row ->
      callback!(callbacks, :objective_satisfaction_gap_status).(row["status"]) and
        callback!(callbacks, :objective_satisfaction_objective_type).(row) in [
          "target_coverage",
          "coverage",
          "target_commitment",
          "priority_commitment",
          "target_observation",
          "target_revisit"
        ]
    end)
  end

  defp objective_satisfaction_report_collection_latency_gap_row_count(report, callbacks) do
    report
    |> objective_satisfaction_report_rows(callbacks)
    |> Enum.count(fn row ->
      callback!(callbacks, :objective_satisfaction_gap_status).(row["status"]) and
        callback!(callbacks, :objective_satisfaction_objective_type).(row) in [
          "collection_latency",
          "collection_downlink_latency",
          "data_latency"
        ]
    end)
  end

  defp objective_satisfaction_report_status_counts(report, callbacks) do
    report
    |> objective_satisfaction_report_rows(callbacks)
    |> callback!(callbacks, :count_objective_satisfaction_rows).("status")
  end

  defp objective_satisfaction_report_objective_type_counts(report, callbacks) do
    report
    |> objective_satisfaction_report_rows(callbacks)
    |> callback!(callbacks, :count_normalized_rows).("objective")
  end

  defp objective_satisfaction_report_ground_station_counts(report, callbacks) do
    report
    |> objective_satisfaction_report_rows(callbacks)
    |> Enum.map(callback!(callbacks, :objective_satisfaction_station_id))
    |> count_source_report_values()
  end

  defp objective_satisfaction_report_target_counts(report, callbacks) do
    report
    |> objective_satisfaction_report_rows(callbacks)
    |> Enum.flat_map(callback!(callbacks, :objective_satisfaction_target_ids))
    |> count_source_report_values()
  end

  defp objective_satisfaction_report_collection_counts(report, callbacks) do
    identity_values = callback!(callbacks, :objective_satisfaction_identity_values)

    report
    |> objective_satisfaction_report_rows(callbacks)
    |> Enum.flat_map(&(identity_values.(&1, "collection_id") || []))
    |> count_source_report_values()
  end

  defp objective_satisfaction_report_source_activity_id_counts(report, callbacks) do
    report
    |> objective_satisfaction_report_rows(callbacks)
    |> Enum.flat_map(
      &(callback!(callbacks, :objective_satisfaction_source_activity_ids).(&1) || [])
    )
    |> count_source_report_values()
  end

  defp objective_tradeoff_report_row_count(report, callbacks) do
    report
    |> callback!(callbacks, :objective_tradeoff_report_rows).()
    |> length()
  end

  defp objective_tradeoff_report_downlink_gap_row_count(report, callbacks) do
    report
    |> objective_tradeoff_report_rows(callbacks)
    |> Enum.count(callback!(callbacks, :objective_tradeoff_downlink_gap))
  end

  defp objective_tradeoff_report_target_gap_row_count(report, callbacks) do
    report
    |> objective_tradeoff_report_rows(callbacks)
    |> Enum.count(callback!(callbacks, :objective_tradeoff_target_gap))
  end

  defp objective_tradeoff_report_collection_latency_gap_row_count(report, callbacks) do
    report
    |> objective_tradeoff_report_rows(callbacks)
    |> Enum.count(callback!(callbacks, :objective_tradeoff_collection_latency_gap))
  end

  defp objective_tradeoff_report_ground_station_counts(report, callbacks) do
    report
    |> objective_tradeoff_report_rows(callbacks)
    |> Enum.map(callback!(callbacks, :objective_tradeoff_station_id))
    |> count_source_report_values()
  end

  defp objective_tradeoff_report_target_counts(report, callbacks) do
    report
    |> objective_tradeoff_report_rows(callbacks)
    |> Enum.flat_map(callback!(callbacks, :objective_satisfaction_target_ids))
    |> count_source_report_values()
  end

  defp objective_tradeoff_report_collection_counts(report, callbacks) do
    identity_values = callback!(callbacks, :objective_satisfaction_identity_values)

    report
    |> objective_tradeoff_report_rows(callbacks)
    |> Enum.flat_map(&(identity_values.(&1, "collection_id") || []))
    |> count_source_report_values()
  end

  defp objective_tradeoff_report_source_activity_id_counts(report, callbacks) do
    report
    |> objective_tradeoff_report_rows(callbacks)
    |> Enum.flat_map(&(callback!(callbacks, :objective_tradeoff_source_activity_ids).(&1) || []))
    |> count_source_report_values()
  end

  defp score_term_report_row_count(report), do: length(Map.get(report, "rows", []))

  defp score_term_report_downlink_gap_row_count(report, callbacks) do
    report
    |> score_term_report_rows(callbacks)
    |> Enum.count(fn row ->
      row
      |> callback!(callbacks, :score_term_key).()
      |> callback!(callbacks, :normalized_timeline_diff_token).()
      |> callback!(callbacks, :score_term_downlink_gap).()
    end)
  end

  defp score_term_report_target_gap_row_count(report, callbacks) do
    report
    |> score_term_report_rows(callbacks)
    |> Enum.count(fn row ->
      row
      |> callback!(callbacks, :score_term_key).()
      |> callback!(callbacks, :normalized_timeline_diff_token).()
      |> callback!(callbacks, :score_term_target_gap).()
    end)
  end

  defp score_term_report_collection_latency_gap_row_count(report, callbacks) do
    report
    |> score_term_report_rows(callbacks)
    |> Enum.count(fn row ->
      row
      |> callback!(callbacks, :score_term_key).()
      |> callback!(callbacks, :normalized_timeline_diff_token).()
      |> callback!(callbacks, :score_term_collection_latency_gap).()
    end)
  end

  defp score_term_report_term_key_counts(report, callbacks) do
    report
    |> score_term_report_rows(callbacks)
    |> Enum.map(fn row ->
      row
      |> callback!(callbacks, :score_term_key).()
      |> callback!(callbacks, :normalized_timeline_diff_token).()
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp score_term_report_ground_station_counts(report, callbacks) do
    report
    |> score_term_report_rows(callbacks)
    |> Enum.map(callback!(callbacks, :score_term_station_id))
    |> count_source_report_values()
  end

  defp score_term_report_target_counts(report, callbacks) do
    report
    |> score_term_report_rows(callbacks)
    |> Enum.flat_map(callback!(callbacks, :objective_satisfaction_target_ids))
    |> count_source_report_values()
  end

  defp score_term_report_collection_counts(report, callbacks) do
    identity_values = callback!(callbacks, :objective_satisfaction_identity_values)

    report
    |> score_term_report_rows(callbacks)
    |> Enum.flat_map(&(identity_values.(&1, "collection_id") || []))
    |> count_source_report_values()
  end

  defp score_term_report_source_activity_id_counts(report, callbacks) do
    report
    |> score_term_report_rows(callbacks)
    |> Enum.flat_map(&(callback!(callbacks, :score_term_source_activity_ids).(&1) || []))
    |> count_source_report_values()
  end

  defp source_objective_satisfaction_report_trust_boundary_status(reports, callbacks) do
    case source_objective_satisfaction_report_trust_boundaries(reports, callbacks) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp source_objective_tradeoff_report_trust_boundary_status(reports, callbacks) do
    case source_objective_tradeoff_report_trust_boundaries(reports, callbacks) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp source_score_term_report_trust_boundary_status(reports, callbacks) do
    case source_score_term_report_trust_boundaries(reports, callbacks) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp source_objective_satisfaction_report_trust_boundaries(reports, callbacks)
       when is_list(reports) do
    reports
    |> Enum.flat_map(&source_objective_satisfaction_report_trust_boundaries(&1, callbacks))
    |> normalize_trust_boundaries()
  end

  defp source_objective_satisfaction_report_trust_boundaries(
         %{"rows" => rows} = report,
         callbacks
       )
       when is_list(rows) do
    row_trust_boundaries =
      rows
      |> Enum.map(callback!(callbacks, :stringify_keys))
      |> Enum.map(
        &Map.put_new(
          &1,
          "_source_report_trust_boundary",
          callback!(callbacks, :result_artifact_trust_boundary).(report)
        )
      )
      |> Enum.map(callback!(callbacks, :objective_satisfaction_trust_boundary))

    row_trust_boundaries ++ source_report_trust_boundaries([report])
  end

  defp source_objective_satisfaction_report_trust_boundaries(%{} = report, _callbacks),
    do: source_report_trust_boundaries([report])

  defp source_objective_tradeoff_report_trust_boundaries(reports, callbacks)
       when is_list(reports) do
    reports
    |> Enum.flat_map(&source_objective_tradeoff_report_trust_boundaries(&1, callbacks))
    |> normalize_trust_boundaries()
  end

  defp source_objective_tradeoff_report_trust_boundaries(%{} = report, callbacks) do
    row_trust_boundaries =
      report
      |> callback!(callbacks, :objective_tradeoff_report_rows).()
      |> Enum.map(callback!(callbacks, :stringify_keys))
      |> Enum.map(
        &Map.put_new(
          &1,
          "_source_report_trust_boundary",
          callback!(callbacks, :result_artifact_trust_boundary).(report)
        )
      )
      |> Enum.map(callback!(callbacks, :objective_tradeoff_trust_boundary))

    row_trust_boundaries ++ source_report_trust_boundaries([report])
  end

  defp source_score_term_report_trust_boundaries(reports, callbacks) when is_list(reports) do
    reports
    |> Enum.flat_map(&source_score_term_report_trust_boundaries(&1, callbacks))
    |> normalize_trust_boundaries()
  end

  defp source_score_term_report_trust_boundaries(%{"rows" => rows} = report, callbacks)
       when is_list(rows) do
    row_trust_boundaries =
      rows
      |> Enum.map(callback!(callbacks, :stringify_keys))
      |> Enum.map(
        &Map.put_new(
          &1,
          "_source_report_trust_boundary",
          callback!(callbacks, :result_artifact_trust_boundary).(report)
        )
      )
      |> Enum.map(callback!(callbacks, :score_term_trust_boundary))

    row_trust_boundaries ++ source_report_trust_boundaries([report])
  end

  defp source_score_term_report_trust_boundaries(%{} = report, _callbacks),
    do: source_report_trust_boundaries([report])

  defp objective_satisfaction_report_rows(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(callback!(callbacks, :stringify_keys))
    |> Enum.map(callback!(callbacks, :normalize_objective_satisfaction_row))
  end

  defp objective_tradeoff_report_rows(report, callbacks) do
    report
    |> callback!(callbacks, :objective_tradeoff_report_rows).()
    |> Enum.map(callback!(callbacks, :stringify_keys))
  end

  defp score_term_report_rows(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(callback!(callbacks, :stringify_keys))
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
