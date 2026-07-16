defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.DirectionFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.SourceFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.SourceFields.TrustBoundaries

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.StationSuppressionFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(DirectionFields.fields(reports))
    |> Map.merge(StationSuppressionFields.fields(reports))
    |> compact_map()
  end

  def source_contact_filter_report_trust_boundaries(reports),
    do: TrustBoundaries.values(reports)
end
