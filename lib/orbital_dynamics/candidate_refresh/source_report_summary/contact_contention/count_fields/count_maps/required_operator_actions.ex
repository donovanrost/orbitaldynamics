defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps.RequiredOperatorActions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.ConflictGroups

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.InvalidInputs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def counts(reports) do
    reports
    |> Enum.map(&count_map/1)
    |> merge_count_maps()
  end

  defp count_map(report) do
    [
      ConflictGroups.required_operator_action_counts(report),
      InvalidInputs.required_operator_action_counts(report)
    ]
    |> merge_count_maps()
    |> empty_counts_if_nil()
  end

  defp empty_counts_if_nil(nil), do: %{}
  defp empty_counts_if_nil(counts), do: counts
end
