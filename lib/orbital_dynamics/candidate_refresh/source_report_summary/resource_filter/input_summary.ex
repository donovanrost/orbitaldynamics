defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.{
    BaseFields,
    CandidateGroups,
    DirectionRouting,
    TrustBoundaries
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)
    source_trust_boundaries = TrustBoundaries.values(reports)

    BaseFields.fields(sources, reports, source_trust_boundaries)
    |> Map.merge(DirectionRouting.fields(reports))
    |> Map.merge(CandidateGroups.fields(reports))
    |> compact_map()
  end
end
