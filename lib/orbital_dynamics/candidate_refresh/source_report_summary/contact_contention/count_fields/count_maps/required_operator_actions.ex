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

  def correlated_counts(conflict_group_count, invalid_contact_input_count, counts)
      when is_map(counts) do
    [
      {"review_contact_contention", conflict_group_count},
      {"review_invalid_contact_contention_input", invalid_contact_input_count}
    ]
    |> Enum.reduce(%{}, fn {action, expected_count}, correlated ->
      count = Map.get(counts, action)

      if is_integer(count) and count > 0 and is_number(expected_count) and expected_count > 0 and
           count <= expected_count do
        Map.put(correlated, action, count)
      else
        correlated
      end
    end)
    |> non_empty_counts()
  end

  def correlated_counts(_conflict_group_count, _invalid_contact_input_count, _counts), do: nil

  defp count_map(report) do
    counts =
      [
        ConflictGroups.required_operator_action_counts(report),
        InvalidInputs.required_operator_action_counts(report)
      ]
      |> merge_count_maps()
      |> empty_counts_if_nil()

    correlated_counts(ConflictGroups.count(report), InvalidInputs.count(report), counts)
  end

  defp empty_counts_if_nil(nil), do: %{}
  defp empty_counts_if_nil(counts), do: counts

  defp non_empty_counts(counts) when map_size(counts) == 0, do: nil
  defp non_empty_counts(counts), do: counts
end
