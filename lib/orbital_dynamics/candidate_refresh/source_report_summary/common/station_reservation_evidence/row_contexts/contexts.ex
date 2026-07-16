defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StationReservationEvidence.RowContexts.Contexts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StationReservationEvidence.RowContexts.SourceReportKeys

  def values(row) do
    row = SourceReportKeys.stringify(row)

    [
      row,
      row["activity_context"],
      row["source_activity_context"],
      row["realized_activity_context"],
      row["import_activity_context"],
      row["source_feedback"],
      row["source_operational_timeline"],
      row["source_review_row"]
    ]
    |> Enum.filter(&is_map/1)
    |> Enum.map(&SourceReportKeys.stringify/1)
  end
end
