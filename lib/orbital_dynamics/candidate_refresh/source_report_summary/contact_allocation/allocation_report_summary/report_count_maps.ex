defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary.ReportCountMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    Map.new(FieldSpecs.count_map_fields(), fn {field, extractor} ->
      {field, count_maps(reports, extractor)}
    end)
  end

  defp count_maps(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
