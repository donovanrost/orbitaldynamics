defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.{
    ReadinessSupport,
    ResourceAvailability,
    SourceFields,
    StatusClassification,
    TimelinePublication
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    sources
    |> SourceFields.fields(reports)
    |> Map.merge(ResourceAvailability.fields(reports))
    |> Map.merge(ReadinessSupport.fields(reports))
    |> Map.merge(StatusClassification.fields(reports))
    |> Map.merge(TimelinePublication.fields(reports))
    |> compact_map()
  end
end
