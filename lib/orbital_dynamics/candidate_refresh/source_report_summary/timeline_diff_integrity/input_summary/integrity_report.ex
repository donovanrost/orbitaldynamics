defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.InputSummary.IntegrityReport do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.SourceFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.CountFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IdFields.AggregateFields,
    as: IdFieldAggregates

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.AggregateFields,
    as: IssueFieldAggregates

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.InputSummary.SourceReports

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def input_summary(sources) do
    reports = SourceReports.values(sources)

    sources
    |> SourceFields.integrity_fields(reports)
    |> Map.merge(CountFields.fields(reports))
    |> Map.merge(IssueFieldAggregates.fields(reports))
    |> Map.merge(IdFieldAggregates.fields(reports))
    |> compact_map()
  end
end
