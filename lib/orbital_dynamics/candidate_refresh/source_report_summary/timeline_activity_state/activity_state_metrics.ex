defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.RowFields
  alias __MODULE__.SourceFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def input_summary(sources) do
    states = Enum.map(sources, fn {_path, state} -> state end)

    SourceFields.fields(sources, states)
    |> Map.merge(RowFields.fields(states))
    |> Map.merge(CountFields.fields(states))
    |> compact_map()
  end
end
