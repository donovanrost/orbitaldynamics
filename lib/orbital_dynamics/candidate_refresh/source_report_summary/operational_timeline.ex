defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline do
  @moduledoc false

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
      "contract" => "operational_timeline_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, callback!(callbacks, :report_rows_count)),
      "contact_feedback_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_timeline_report_contact_feedback_count)
        ),
      "command_feedback_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_timeline_report_command_feedback_count)
        ),
      "maneuver_feedback_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_timeline_report_maneuver_feedback_count)
        ),
      "observation_feedback_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_timeline_report_observation_feedback_count)
        ),
      "station_throughput_feedback_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_timeline_report_station_throughput_feedback_count)
        ),
      "operational_kind_counts" =>
        reports
        |> Enum.map(
          &operational_timeline_report_row_field_counts(&1, "operational_kind", callbacks)
        )
        |> merge_count_maps(),
      "activity_id_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :operational_timeline_report_activity_id_counts))
        |> merge_count_maps(),
      "activity_status_counts" =>
        reports
        |> Enum.map(&operational_timeline_report_row_field_counts(&1, "status", callbacks))
        |> merge_count_maps(),
      "approval_status_counts" =>
        reports
        |> Enum.map(
          &operational_timeline_report_row_field_counts(&1, "approval_status", callbacks)
        )
        |> merge_count_maps(),
      "required_operator_action_counts" =>
        reports
        |> Enum.map(
          &operational_timeline_report_row_field_counts(
            &1,
            "required_operator_action",
            callbacks
          )
        )
        |> merge_count_maps(),
      "cadence_import_status_counts" =>
        reports
        |> Enum.map(
          &operational_timeline_report_row_field_counts(&1, "cadence_import_status", callbacks)
        )
        |> merge_count_maps(),
      "timeline_integrity_issue_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_timeline_report_integrity_issue_count)
        ),
      "dependency_integrity_issue_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_timeline_report_dependency_issue_count)
        ),
      "exclusivity_integrity_issue_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_timeline_report_exclusivity_issue_count)
        ),
      "timeline_integrity_issue_type_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :operational_timeline_report_integrity_issue_type_counts)
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
      "input_keys" =>
        callback!(callbacks, :source_report_feedback_input_keys).(
          reports,
          callback!(callbacks, :operational_timeline_report_operational_feedback)
        ),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_operational_timeline_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_operational_timeline_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp operational_timeline_report_row_field_counts(report, field, callbacks) do
    callback!(callbacks, :operational_timeline_report_row_field_counts).(report, field)
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
