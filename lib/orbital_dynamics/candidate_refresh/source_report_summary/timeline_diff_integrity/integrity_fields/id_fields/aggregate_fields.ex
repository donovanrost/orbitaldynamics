defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IdFields.AggregateFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IdFields.ValueCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    reports
    |> review_fields()
    |> Map.merge(count_fields(reports, FieldSpecs.dependency()))
    |> Map.merge(count_fields(reports, FieldSpecs.exclusivity()))
  end

  defp count_fields(reports, specs) do
    Map.new(specs, fn {field, source_fields} ->
      count =
        reports
        |> Enum.map(&ValueCounts.id_counts(&1, source_fields))
        |> merge_count_maps()

      {field, count}
    end)
  end

  defp review_fields(reports) do
    Map.new(FieldSpecs.review(), fn {field, source_fields} ->
      count =
        reports
        |> Enum.map(&ValueCounts.row_unique_counts(&1, source_fields))
        |> merge_count_maps()

      {field, count}
    end)
  end
end
