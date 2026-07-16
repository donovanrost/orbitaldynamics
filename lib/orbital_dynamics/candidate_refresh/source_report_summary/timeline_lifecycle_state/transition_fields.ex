defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.TransitionFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(summaries) do
    summaries
    |> transition_count_fields()
    |> Map.merge(RowFields.transition_provenance_fields(summaries))
  end

  defp transition_count_fields(summaries) do
    Map.new(FieldSpecs.transition_count_fields(), fn field ->
      {field, count_map(summaries, field)}
    end)
  end

  defp count_map(summaries, field) do
    summaries
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_count_maps()
  end
end
