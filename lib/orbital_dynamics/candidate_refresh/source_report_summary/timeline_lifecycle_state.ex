defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.ReviewFields
  alias __MODULE__.RowFields
  alias __MODULE__.SourceFields
  alias __MODULE__.TransitionFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    summaries =
      Enum.map(sources, fn {_path, summary} ->
        RowFields.put_derived(summary)
      end)

    SourceFields.fields(sources, summaries)
    |> Map.merge(CountFields.fields(summaries))
    |> Map.merge(ReviewFields.fields(summaries))
    |> Map.merge(TransitionFields.fields(summaries))
    |> compact_map()
  end
end
