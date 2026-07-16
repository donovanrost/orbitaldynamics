defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.ReservationFields.IdMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report
  alias __MODULE__.ReportMaps

  def fields(reports) do
    %{
      "affected_contact_ids" => Report.affected_contact_ids(reports),
      "contact_ids_by_match_status" =>
        ReportMaps.string_list(reports, &Report.contact_ids_by_match_status/1),
      "contact_ids_by_status" => ReportMaps.string_list(reports, &Report.contact_ids_by_status/1),
      "reservation_ids" => Report.ids(reports),
      "reservation_ids_by_match_status" =>
        ReportMaps.string_list(reports, &Report.ids_by_match_status/1),
      "reservation_ids_by_status" => ReportMaps.string_list(reports, &Report.ids_by_status/1),
      "reserved_by_counts" => ReportMaps.counts(reports, &Report.reserved_by_counts/1),
      "contact_ids_by_reserved_by" =>
        ReportMaps.string_list(reports, &Report.contact_ids_by_reserved_by/1),
      "reservation_ids_by_reserved_by" =>
        ReportMaps.string_list(reports, &Report.ids_by_reserved_by/1)
    }
  end
end
