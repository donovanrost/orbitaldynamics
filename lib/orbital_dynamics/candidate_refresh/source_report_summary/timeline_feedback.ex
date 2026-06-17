defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "timeline_feedback_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, callback!(callbacks, :report_rows_count)),
      "input_keys" =>
        callback!(callbacks, :source_report_feedback_input_keys).(
          reports,
          &TimelineFeedback.operational_feedback/1
        ),
      "status_counts" =>
        reports
        |> Enum.map(&timeline_feedback_report_row_field_counts(&1, "status", callbacks))
        |> merge_count_maps(),
      "feedback_kind_counts" =>
        reports
        |> Enum.map(&timeline_feedback_report_row_field_counts(&1, "feedback_kind", callbacks))
        |> merge_count_maps(),
      "match_strategy_counts" =>
        reports
        |> Enum.map(&timeline_feedback_report_row_field_counts(&1, "match_strategy", callbacks))
        |> merge_count_maps(),
      "activity_id_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :timeline_feedback_report_activity_id_counts))
        |> merge_count_maps(),
      "cadence_import_status_counts" =>
        reports
        |> Enum.map(
          &timeline_feedback_report_row_field_counts(&1, "cadence_import_status", callbacks)
        )
        |> merge_count_maps(),
      "station_reservation_evidence_row_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :report_station_reservation_evidence_count)
        ),
      "station_reservation_expiration_evidence_row_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :report_station_reservation_expiration_evidence_count)
        ),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_timeline_feedback_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_timeline_feedback_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp timeline_feedback_report_row_field_counts(report, field, callbacks) do
    callback!(callbacks, :timeline_feedback_report_row_field_counts).(report, field)
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
