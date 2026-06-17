defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Aggregation
  alias __MODULE__.Allocation
  alias __MODULE__.CapacityPack
  alias __MODULE__.ProviderReservation
  alias __MODULE__.ReservationConflict
  alias __MODULE__.StationPressure
  alias __MODULE__.StationReservation

  import Aggregation,
    except: [
      contact_allocation_capacity_pack_contact_count: 1,
      contact_allocation_reservation_conflict_contact_count: 1,
      contact_allocation_station_pressure_contact_count: 1,
      contact_allocation_station_pressure_review_contact_count: 1,
      summary_nested_string_list_map_fields: 2
    ]

  def source_report_summary_fields(source_reports, pressure_fields) do
    source_reports
    |> source_report_identity_fields()
    |> Map.merge(source_report_capacity_pack_fields(source_reports))
    |> Map.merge(source_report_allocation_fields(source_reports))
    |> Map.merge(source_report_station_pressure_fields(source_reports))
    |> Map.merge(source_report_station_reservation_fields(source_reports))
    |> Map.merge(source_report_reservation_conflict_fields(source_reports))
    |> Map.merge(source_report_provider_reservation_fields(source_reports))
    |> Map.merge(pressure_fields.(source_reports))
  end

  def source_report_identity_fields(source_reports) do
    %{
      "source_report_contact_allocation_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_contact_allocation_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_contact_allocation_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_contact_allocation_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_contact_allocation_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_contact_allocation_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_contact_allocation_source_artifact_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_artifact_type_counts")
    }
  end

  def source_report_station_pressure_fields(source_reports) do
    StationPressure.source_report_station_pressure_fields(source_reports)
  end

  def source_report_capacity_pack_fields(source_reports) do
    CapacityPack.source_report_capacity_pack_fields(source_reports)
  end

  def source_report_allocation_fields(source_reports) do
    Allocation.source_report_allocation_fields(source_reports)
  end

  def source_report_station_reservation_fields(source_reports) do
    StationReservation.source_report_station_reservation_fields(source_reports)
  end

  def source_report_reservation_conflict_fields(source_reports) do
    ReservationConflict.source_report_reservation_conflict_fields(source_reports)
  end

  def source_report_provider_reservation_fields(source_reports) do
    ProviderReservation.source_report_provider_reservation_fields(source_reports)
  end

  def contact_allocation_capacity_pack_contact_count(summary) do
    Aggregation.contact_allocation_capacity_pack_contact_count(summary)
  end

  def contact_allocation_station_pressure_contact_count(summary) do
    Aggregation.contact_allocation_station_pressure_contact_count(summary)
  end

  def contact_allocation_station_pressure_review_contact_count(summary) do
    Aggregation.contact_allocation_station_pressure_review_contact_count(summary)
  end

  def contact_allocation_reservation_conflict_contact_count(summary) do
    Aggregation.contact_allocation_reservation_conflict_contact_count(summary)
  end

  def summary_nested_string_list_map_fields(summary, fields) do
    Aggregation.summary_nested_string_list_map_fields(summary, fields)
  end
end
