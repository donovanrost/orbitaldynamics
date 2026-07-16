defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationReservationSummary.ExpirationFields.Aggregates do
  @moduledoc false

  alias __MODULE__.NumericValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def count_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  def string_list_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end

  def min_report_value(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  def numeric_list_merge(reports, extractor) do
    reports
    |> Enum.flat_map(&(extractor.(&1) || []))
    |> NumericValues.normalize()
  end
end
