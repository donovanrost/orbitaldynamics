defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary.ReportCountMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CountMapCorrelation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    Map.new(FieldSpecs.count_map_fields(), fn {field, extractor} ->
      {field, count_maps(reports, field, extractor)}
    end)
  end

  defp count_maps(reports, field, extractor) do
    count_maps = Enum.map(reports, extractor)

    count_maps
    |> normalize_base_count_maps(field)
    |> merge_count_maps()
  end

  defp normalize_base_count_maps(count_maps, field) do
    if field in CountMapCorrelation.count_fields(),
      do: Enum.map(count_maps, &CountMapCorrelation.positive_counts/1),
      else: count_maps
  end
end
