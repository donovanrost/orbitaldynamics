defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.InputSummary do
  @moduledoc false

  alias __MODULE__.IntegrityReport
  alias __MODULE__.TimelineDiffReport

  defdelegate timeline_diff_report_input_summary(sources),
    to: TimelineDiffReport,
    as: :input_summary

  defdelegate integrity_report_input_summary(sources), to: IntegrityReport, as: :input_summary
end
