defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.{
    BaseFields,
    PressureFields,
    TrustBoundaries
  }

  alias __MODULE__.SourceReports

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary(sources) do
    reports = SourceReports.values(sources)

    BaseFields.fields(sources, reports)
    |> Map.merge(PressureFields.fields(reports))
    |> Map.merge(%{
      "trust_boundary_status" => TrustBoundaries.status(reports),
      "trust_boundaries" => TrustBoundaries.values(reports)
    })
    |> compact_map()
  end
end
