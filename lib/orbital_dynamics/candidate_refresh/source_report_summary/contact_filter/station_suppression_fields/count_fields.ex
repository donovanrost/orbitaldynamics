defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.StationSuppressionFields.CountFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1, sum_report_count: 2]

  def fields(reports) do
    count_fields =
      Map.new(FieldSpecs.values(), fn {field, field_fun} ->
        {field, count_map(reports, field_fun)}
      end)

    Map.merge(count_fields, %{
      "station_suppression_count" =>
        sum_report_count(reports, &Report.station_suppression_count/1)
    })
  end

  defp count_map(reports, field_fun) do
    reports
    |> Enum.map(field_fun)
    |> merge_count_maps()
  end
end
