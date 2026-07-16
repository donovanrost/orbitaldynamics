defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics.SourceCountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics.RowValues

  def fields(report) do
    %{
      "source_report_status_counts" =>
        RowValues.source_count_map(report, "status_counts", "status"),
      "source_feedback_kind_counts" =>
        RowValues.source_count_map(report, "feedback_kind_counts", "feedback_kind"),
      "source_match_strategy_counts" =>
        RowValues.source_count_map(report, "match_strategy_counts", "match_strategy"),
      "source_cadence_import_status_counts" =>
        RowValues.source_count_map(
          report,
          "cadence_import_status_counts",
          "cadence_import_status"
        )
    }
  end
end
