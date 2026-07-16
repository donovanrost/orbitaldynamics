defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.SourceFields.StatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.StatusFields.RowCounts,
    as: StatusRowCounts

  def values(report) do
    %{
      "source_diff_status_counts" =>
        StatusRowCounts.source(report, "diff_status_counts", "diff_status"),
      "source_required_operator_action_counts" =>
        StatusRowCounts.source(
          report,
          "required_operator_action_counts",
          "required_operator_action"
        )
    }
  end
end
