defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.ContactSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.Normalization
  alias __MODULE__.Pairs
  alias __MODULE__.StationEntries

  def suppressed_reason_contact_pairs(report) do
    Pairs.suppressed_reason_contact_pairs(report)
  end

  def direction_contact_pairs(report) do
    Pairs.direction_contact_pairs(report)
  end

  def row_contact_id(row) do
    [
      row["contact_id"],
      row["id"],
      row["candidate_id"],
      row["source_contact_id"],
      row["source_candidate_id"],
      get_in(row, ["activity_context", "contact_id"]),
      get_in(row, ["activity_context", "id"]),
      get_in(row, ["source_contact_candidate", "contact_id"]),
      get_in(row, ["source_contact_candidate", "id"]),
      get_in(row, ["contact_candidate", "contact_id"]),
      get_in(row, ["contact_candidate", "id"])
    ]
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  def row_station_calendar_entry_id(row) do
    StationEntries.station_calendar_entry_id(row)
  end

  def row_station_calendar_provider_entry_id(row) do
    StationEntries.station_calendar_provider_entry_id(row)
  end

  def row_station_reservation_id(row) do
    StationEntries.station_reservation_id(row)
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
end
