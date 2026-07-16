defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.HoldFields.CountStatusFields.ExpirationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    %{
      "reservation_hold_expiration_count" =>
        Report.optional_count_sum(reports, "reservation_hold_expiration_count"),
      "earliest_reservation_hold_expires_at_s" => earliest_hold_expiration(reports),
      "reservation_hold_expiration_status_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_expiration_status_counts"))
        |> merge_count_maps()
    }
  end

  defp earliest_hold_expiration(reports) do
    reports
    |> Enum.map(&(Map.get(&1, "earliest_reservation_hold_expires_at_s") |> NumericValue.value()))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end
end
