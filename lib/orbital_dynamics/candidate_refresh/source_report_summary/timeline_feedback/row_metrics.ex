defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics do
  @moduledoc false

  alias __MODULE__.CountMaps
  alias __MODULE__.InputKeys
  alias __MODULE__.RowValues
  alias __MODULE__.SourceCountFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &row_count/1),
      "input_keys" => input_keys(reports),
      "status_counts" => CountMaps.field_counts(reports, "status"),
      "feedback_kind_counts" => CountMaps.field_counts(reports, "feedback_kind"),
      "match_strategy_counts" => CountMaps.field_counts(reports, "match_strategy"),
      "activity_id_counts" => CountMaps.activity_id_counts(reports),
      "cadence_import_status_counts" => CountMaps.field_counts(reports, "cadence_import_status")
    }
  end

  def row_count(report), do: RowValues.row_count(report)

  def input_keys_from_feedback(feedback) do
    InputKeys.from_feedback(feedback)
  end

  def source_count_fields(report) do
    SourceCountFields.fields(report)
  end

  defp input_keys(reports) do
    InputKeys.from_reports(reports)
  end
end
