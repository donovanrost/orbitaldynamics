defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary
  alias __MODULE__.Aggregation
  alias __MODULE__.Allocation
  alias __MODULE__.CapacityPack
  alias __MODULE__.Pressure
  alias __MODULE__.ProviderReservation.SourceReportFields, as: ProviderReservationFields
  alias __MODULE__.ReservationConflict
  alias __MODULE__.StationPressure
  alias __MODULE__.StationReservation.SourceReportFields, as: StationReservationFields

  import Aggregation,
    except: [
      contact_allocation_capacity_pack_contact_count: 1,
      contact_allocation_reservation_conflict_contact_count: 1,
      contact_allocation_station_pressure_contact_count: 1,
      contact_allocation_station_pressure_review_contact_count: 1,
      summary_nested_string_list_map_fields: 2
    ]

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_identity_fields()
    |> Map.merge(CapacityPack.source_report_capacity_pack_fields(source_reports))
    |> Map.merge(Allocation.source_report_allocation_fields(source_reports))
    |> Map.merge(StationPressure.source_report_station_pressure_fields(source_reports))
    |> Map.merge(
      StationReservationFields.source_report_station_reservation_fields(source_reports)
    )
    |> Map.merge(ReservationConflict.source_report_reservation_conflict_fields(source_reports))
    |> Map.merge(
      ProviderReservationFields.source_report_provider_reservation_fields(source_reports)
    )
    |> Map.merge(source_report_fields(source_reports))
  end

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("contact_allocation_report", %{})
      |> Summary.summary(
        "candidate_refresh.source_report_provenance.contact_allocation_report",
        "contact_allocation_source_report_provenance_only"
      )

    Pressure.source_report_fields(summary)
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
