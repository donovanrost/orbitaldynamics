defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields.Flattened.StationFeedback do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields.Flattened.Aggregation

  def fields(source_reports) do
    %{
      "source_report_contact_intent_station_feedback_count" =>
        source_report_family_count(source_reports, "station_feedback_count"),
      "source_report_contact_intent_station_calendar_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "station_calendar_status_counts"),
      "source_report_contact_intent_cadence_import_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "cadence_import_status_counts"),
      "source_report_contact_intent_policy_classification_counts" =>
        source_report_family_merge_count_maps(source_reports, "policy_classification_counts")
    }
  end
end
