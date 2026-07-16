defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.IdMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    Map.new(FieldSpecs.all(), fn {field, fallback_field} ->
      {field, string_list_map(reports, field, fallback_field)}
    end)
  end

  defp string_list_map(reports, field, fallback_field) do
    reports
    |> Enum.map(&report_string_list_map(&1, field, fallback_field))
    |> merge_string_list_maps()
  end

  defp report_string_list_map(report, field, nil) do
    RowFallbackValues.string_list_map(report, field)
  end

  defp report_string_list_map(report, field, fallback_field) do
    case RowFallbackValues.string_list_map(report, field) do
      map when map_size(map) > 0 -> map
      _map -> RowFallbackValues.string_list_map(report, fallback_field)
    end
  end
end
