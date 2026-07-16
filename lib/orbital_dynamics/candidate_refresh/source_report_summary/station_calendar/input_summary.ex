defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.{
    DirectionRouting,
    PrecedenceFields,
    ProviderContentionFields,
    SourceFields,
    StationFields
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(StationFields.fields(reports))
    |> Map.merge(DirectionRouting.fields(reports))
    |> Map.merge(ProviderContentionFields.fields(reports))
    |> Map.merge(PrecedenceFields.fields(reports))
    |> compact_map()
  end
end
