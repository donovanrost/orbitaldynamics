defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.PreconditionFields
  alias __MODULE__.SourceFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    summaries = Enum.map(sources, fn {_path, summary} -> summary end)

    SourceFields.fields(sources, summaries)
    |> Map.merge(count_fields(summaries))
    |> compact_map()
  end

  defp count_fields(summaries) do
    PreconditionFields.fields(summaries)
    |> Map.merge(CountFields.fields(summaries))
  end
end
