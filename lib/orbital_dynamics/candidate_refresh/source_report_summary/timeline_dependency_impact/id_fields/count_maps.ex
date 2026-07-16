defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.IdFields.CountMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.IdFields.ValueCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def fields(reports) do
    reports
    |> count_fields()
    |> Kernel.++(row_unique_count_fields(reports))
    |> Map.new()
  end

  defp count_fields(reports) do
    Enum.map(FieldSpecs.count_fields(), fn {field, report_fields} ->
      {field, count_map(reports, &ValueCounts.count(&1, report_fields))}
    end)
  end

  defp row_unique_count_fields(reports) do
    Enum.map(FieldSpecs.row_unique_count_fields(), fn {field, report_fields} ->
      {field, count_map(reports, &ValueCounts.row_unique_count(&1, report_fields))}
    end)
  end

  defp count_map(reports, count_fun) do
    reports
    |> Enum.map(count_fun)
    |> merge_count_maps()
  end
end
