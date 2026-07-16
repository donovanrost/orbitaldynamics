defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication do
  @moduledoc false

  alias __MODULE__.DependencyFields
  alias __MODULE__.DiffFields
  alias __MODULE__.SourceFields
  alias __MODULE__.SummaryFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    summaries = Enum.map(sources, fn {_path, summary} -> summary end)

    SourceFields.fields(sources, summaries)
    |> Map.merge(SummaryFields.fields(summaries))
    |> Map.merge(DependencyFields.fields(summaries))
    |> Map.merge(DiffFields.fields(summaries))
    |> compact_map()
  end
end
