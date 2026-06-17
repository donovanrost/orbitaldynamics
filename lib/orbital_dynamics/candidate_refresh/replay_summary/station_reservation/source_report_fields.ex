defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields do
  @moduledoc false

  alias __MODULE__.ProviderContention
  alias __MODULE__.ReservationHold

  import __MODULE__.Aggregation

  def source_report_fields(source_reports, pressure_fields) do
    source_reports
    |> source_report_fields()
    |> Map.merge(pressure_fields)
    |> compact_map()
  end

  def source_report_fields(source_reports) do
    %{
      "source_report_station_reservation_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_station_reservation_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_station_reservation_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_station_reservation_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_station_reservation_evidence_row_count" =>
        source_report_count(source_reports, "station_reservation_evidence_row_count"),
      "source_report_station_reservation_expiration_evidence_row_count" =>
        source_report_count(source_reports, "station_reservation_expiration_evidence_row_count"),
      "source_report_station_reservation_evidence_row_counts_by_family" =>
        source_report_counts_by_family(source_reports, "station_reservation_evidence_row_count"),
      "source_report_station_reservation_expiration_evidence_row_counts_by_family" =>
        source_report_counts_by_family(
          source_reports,
          "station_reservation_expiration_evidence_row_count"
        ),
      "source_report_station_reservation_affected_contact_count" =>
        source_report_family_count(source_reports, "affected_contact_count"),
      "source_report_station_reservation_reservation_review_count" =>
        source_report_family_count(source_reports, "reservation_review_count"),
      "source_report_station_reservation_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_station_reservation_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_station_reservation_source_artifact_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_artifact_type_counts"),
      "source_report_station_reservation_affected_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "affected_contact_ids"),
      "source_report_station_reservation_contact_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_match_status"
        ),
      "source_report_station_reservation_contact_ids_by_status" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_status"),
      "source_report_station_reservation_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_station_reservation_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_direction"),
      "source_report_station_reservation_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing"),
      "source_report_station_reservation_expires_at_s" =>
        source_report_family_merge_numeric_lists(source_reports, "reservation_expires_at_s"),
      "source_report_station_reservation_earliest_expires_at_s" =>
        source_report_family_numeric_min(source_reports, "earliest_reservation_expires_at_s"),
      "source_report_station_reservation_match_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_reservation_match_status_counts"
        ),
      "source_report_station_reservation_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "reservation_status_counts"),
      "source_report_station_reservation_ids" =>
        source_report_family_merge_string_lists(source_reports, "reservation_ids"),
      "source_report_station_reservation_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_ids_by_match_status"
        ),
      "source_report_station_reservation_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_ids_by_status"
        ),
      "source_report_station_reservation_reserved_by_counts" =>
        source_report_family_merge_count_maps(source_reports, "reserved_by_counts"),
      "source_report_station_reservation_contact_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_reserved_by"
        ),
      "source_report_station_reservation_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_ids_by_reserved_by"
        )
    }
    |> Map.merge(ProviderContention.source_report_provider_contention_fields(source_reports))
    |> Map.merge(ReservationHold.source_report_reservation_hold_fields(source_reports))
  end
end
