defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.CountFields.IdentityFields.CountMaps do
  @moduledoc false

  alias __MODULE__.IdCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      merge_count_maps: 1
    ]

  def list(summaries, field) do
    summaries
    |> Enum.map(&list_counts(&1, field))
    |> merge_count_maps()
  end

  def id(summaries, field) do
    summaries
    |> Enum.map(&IdCounts.values(&1, field))
    |> merge_count_maps()
  end

  defp list_counts(%{} = summary, field) do
    summary
    |> Map.get(field)
    |> List.wrap()
    |> count_source_report_values()
  end

  defp list_counts(_summary, _field), do: %{}
end
