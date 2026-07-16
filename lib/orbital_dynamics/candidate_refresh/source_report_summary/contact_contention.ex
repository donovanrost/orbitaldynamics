defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.DirectionRouting
  alias __MODULE__.SourceFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(DirectionRouting.fields(reports))
    |> Map.merge(CountFields.fields(reports))
    |> compact_map()
  end
end
