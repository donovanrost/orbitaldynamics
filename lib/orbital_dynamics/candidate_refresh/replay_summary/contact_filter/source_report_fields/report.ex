defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.StationSuppression

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.SuppressionFields

  defdelegate row_count(report), to: SuppressionFields

  defdelegate suppressed_candidate_count(report), to: SuppressionFields

  defdelegate invalid_contact_input_count(report), to: SuppressionFields

  defdelegate invalid_contact_input_ids(report), to: SuppressionFields

  defdelegate suppressed_reason_counts(report), to: SuppressionFields

  defdelegate contact_ids_by_suppressed_reason(report), to: SuppressionFields

  defdelegate direction_counts(report), to: SuppressionFields

  defdelegate contact_ids_by_direction(report), to: SuppressionFields

  defdelegate station_suppression_count(report), to: StationSuppression
  defdelegate station_suppression_ground_station_counts(report), to: StationSuppression
  defdelegate station_suppression_availability_counts(report), to: StationSuppression
  defdelegate station_suppression_status_counts(report), to: StationSuppression
  defdelegate station_suppression_contact_ids_by_ground_station(report), to: StationSuppression
  defdelegate station_suppression_contact_ids_by_availability(report), to: StationSuppression
  defdelegate station_suppression_contact_ids_by_status(report), to: StationSuppression

  defdelegate station_suppression_station_calendar_entry_ids_by_ground_station(report),
    to: StationSuppression

  defdelegate station_suppression_station_calendar_entry_ids_by_availability(report),
    to: StationSuppression

  defdelegate station_suppression_station_calendar_entry_ids_by_status(report),
    to: StationSuppression

  defdelegate station_suppression_station_calendar_provider_entry_ids_by_ground_station(report),
    to: StationSuppression

  defdelegate station_suppression_station_calendar_provider_entry_ids_by_availability(report),
    to: StationSuppression

  defdelegate station_suppression_station_calendar_provider_entry_ids_by_status(report),
    to: StationSuppression

  defdelegate station_suppression_station_reservation_ids_by_ground_station(report),
    to: StationSuppression

  defdelegate station_suppression_station_reservation_ids_by_availability(report),
    to: StationSuppression

  defdelegate station_suppression_station_reservation_ids_by_status(report),
    to: StationSuppression
end
