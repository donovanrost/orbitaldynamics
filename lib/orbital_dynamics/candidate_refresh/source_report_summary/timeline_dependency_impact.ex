defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.IdFields
  alias __MODULE__.SourceFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(aggregate_fields(reports))
    |> compact_map()
  end

  defp aggregate_fields(reports) do
    CountFields.fields(reports)
    |> Map.merge(IdFields.fields(reports))
  end
end
