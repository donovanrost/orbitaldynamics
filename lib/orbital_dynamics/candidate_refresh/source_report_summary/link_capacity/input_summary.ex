defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.{
    DirectionFields,
    RelayFields,
    ReportNormalizer,
    RoutingMaps,
    SourceFields,
    ThroughputFields
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> ReportNormalizer.normalize(report) end)

    SourceFields.fields(sources, reports)
    |> Map.merge(RoutingMaps.fields(reports))
    |> Map.merge(ThroughputFields.fields(reports))
    |> Map.merge(DirectionFields.fields(reports))
    |> Map.merge(RelayFields.fields(reports))
    |> compact_map()
  end
end
