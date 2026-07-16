defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.IssueTypes do
  @moduledoc false

  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [source_rows: 1]

  def values(report) do
    report
    |> source_rows()
    |> Enum.flat_map(&RowValues.issue_types/1)
  end
end
