defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.GroupedIds.DirectionCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows,
    only: [
      direction_contact_pairs: 1,
      grouped_source_report_id_counts: 1,
      rows_for_summary: 1
    ]

  def direction_counts(report) do
    report
    |> rows_for_summary()
    |> Enum.flat_map(&direction_contact_pairs/1)
    |> grouped_source_report_id_counts()
  end
end
