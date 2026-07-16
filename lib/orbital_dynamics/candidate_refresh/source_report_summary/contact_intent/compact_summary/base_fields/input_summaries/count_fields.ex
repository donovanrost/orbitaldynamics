defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.AggregateValues

  def fields(summaries) do
    %{
      "paths" => AggregateValues.paths(summaries),
      "count" => AggregateValues.count(summaries, "count"),
      "row_count" => AggregateValues.count(summaries, "row_count"),
      "source_summary_model_counts" =>
        AggregateValues.count_map(summaries, "source_summary_model_counts"),
      "source_summary_schema_contract_counts" =>
        AggregateValues.count_map(summaries, "source_summary_schema_contract_counts"),
      "source_artifact_type_counts" =>
        AggregateValues.count_map(summaries, "source_artifact_type_counts"),
      "station_feedback_count" => AggregateValues.count(summaries, "station_feedback_count"),
      "station_calendar_status_counts" =>
        AggregateValues.count_map(summaries, "station_calendar_status_counts"),
      "cadence_import_status_counts" =>
        AggregateValues.count_map(summaries, "cadence_import_status_counts"),
      "policy_classification_counts" =>
        AggregateValues.count_map(summaries, "policy_classification_counts"),
      "capacity_pack_required_contact_count" =>
        AggregateValues.count(summaries, "capacity_pack_required_contact_count")
    }
  end
end
