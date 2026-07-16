defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.GroupedIds.GroupedMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows,
    only: [
      explicit_string_list_map: 2,
      grouped_source_report_ids: 1,
      rows_for_summary: 1
    ]

  def grouped_ids_by_spacecraft(report, pair_fun, fallback_field) do
    report
    |> rows_for_summary()
    |> Enum.flat_map(pair_fun)
    |> grouped_source_report_ids()
    |> case do
      nil -> explicit_string_list_map(report, fallback_field)
      ids_by_spacecraft -> ids_by_spacecraft
    end
  end
end
