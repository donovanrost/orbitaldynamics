defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.CapacityFields.CapacityMaps.MapFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_numeric_maps: 1,
      merge_string_list_maps: 1
    ]

  def count_field(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_count_maps()
  end

  def numeric(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_numeric_maps()
  end

  def numeric_field(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_numeric_maps()
  end

  def string_list_field(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_string_list_maps()
  end
end
