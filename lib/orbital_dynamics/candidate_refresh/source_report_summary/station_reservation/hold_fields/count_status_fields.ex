defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.HoldFields.CountStatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report
  alias __MODULE__.ExpirationFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2,
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "reservation_review_count" => sum_report_count(reports, &Report.review_count/1),
      "reservation_hold_count" => Report.optional_count_sum(reports, "reservation_hold_count"),
      "affected_contact_reservation_hold_count" =>
        Report.optional_count_sum(reports, "affected_contact_reservation_hold_count"),
      "provider_calendar_contention_hold_count" =>
        Report.optional_count_sum(reports, "provider_calendar_contention_hold_count"),
      "reservation_hold_review_status_counts" =>
        reports
        |> count_report_field_values("reservation_hold_review_status"),
      "reservation_hold_status_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_status_counts"))
        |> merge_count_maps()
    }
    |> Map.merge(ExpirationFields.fields(reports))
  end
end
