defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds.SourceWindowIds.RawValues do
  @moduledoc false

  def values(row) do
    [
      row["source_window_id"],
      row["source_window_ids"],
      get_in(row, ["source_window", "id"]),
      get_in(row, ["first_resource_pressure", "source_window_id"]),
      get_in(row, ["source_activity", "source_window_id"]),
      get_in(row, ["source_contact", "source_window_id"])
    ]
  end
end
