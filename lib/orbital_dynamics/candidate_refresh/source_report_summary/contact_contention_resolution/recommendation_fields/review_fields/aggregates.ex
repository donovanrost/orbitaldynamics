defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ReviewFields.Aggregates do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      sorted_string_values: 1
    ]

  def count_map(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  def string_list_map_field(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_string_list_maps()
  end

  def sorted_field_values(reports, field) do
    reports
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
    |> non_empty_list()
  end

  defp non_empty_list([]), do: nil
  defp non_empty_list(list), do: list
end
