defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.CountFields.CountMapFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.CountFields.CountMapSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      merge_count_maps: 1,
      source_rows: 1
    ]

  def fields(reports) do
    Map.new(CountMapSpecs.all(), fn {field, fallback_field, row_field} ->
      {field, count_maps(reports, fallback_field, row_field)}
    end)
  end

  defp count_maps(reports, fallback_field, row_field) do
    reports
    |> Enum.map(&count_map(&1, fallback_field, row_field))
    |> merge_count_maps()
  end

  defp count_map(report, top_level_field, row_field) do
    case source_rows(report) do
      [] ->
        Map.get(report, top_level_field)

      rows ->
        rows
        |> Enum.map(&Map.get(&1, row_field))
        |> count_source_report_values()
    end
  end
end
