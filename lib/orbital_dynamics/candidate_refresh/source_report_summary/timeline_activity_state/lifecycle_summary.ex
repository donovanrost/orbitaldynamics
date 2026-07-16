defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary do
  @moduledoc false

  alias __MODULE__.IdentityFields
  alias __MODULE__.MetricFields
  alias __MODULE__.TransitionCounts
  alias __MODULE__.TransitionProvenance

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.SourceSummary

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def input_summary(sources) do
    states = Enum.map(sources, fn {_path, state} -> state end)

    source_fields(sources, states)
    |> Map.merge(fields(states))
    |> compact_map()
  end

  defp source_fields(sources, states) do
    %{
      "paths" => Enum.map(sources, fn {path, _state} -> path end),
      "contract" => SourceSummary.input_summary_contract(states),
      "count" => length(sources)
    }
  end

  defp fields(states) do
    MetricFields.fields(states)
    |> Map.merge(IdentityFields.fields(states))
    |> Map.merge(TransitionCounts.fields(states))
    |> Map.merge(TransitionProvenance.fields(states))
  end
end
