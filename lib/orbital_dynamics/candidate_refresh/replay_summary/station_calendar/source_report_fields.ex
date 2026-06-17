defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Direction
  alias __MODULE__.Precedence
  alias __MODULE__.ProviderContention
  alias __MODULE__.ReservationCapacityStatus

  import __MODULE__.Aggregation

  def source_report_fields(summary) do
    %{
      "source_report_station_calendar_branch_local_station_calendar_pressure" =>
        Map.get(summary, "branch_local_station_calendar_pressure"),
      "source_report_station_calendar_branch_local_affected_contact_pressure" =>
        Map.get(summary, "branch_local_affected_contact_pressure"),
      "source_report_station_calendar_branch_local_provider_contention_pressure" =>
        Map.get(summary, "branch_local_provider_contention_pressure"),
      "source_report_station_calendar_branch_local_station_availability_pressure" =>
        Map.get(summary, "branch_local_station_availability_pressure")
    }
  end

  def source_report_summary_fields(source_reports, pressure_fields) do
    pressure_fields
    |> Map.merge(source_report_identity_fields(source_reports))
    |> Map.merge(source_report_source_metadata_fields(source_reports))
    |> Map.merge(source_report_provider_contention_fields(source_reports))
    |> Map.merge(source_report_direction_fields(source_reports))
    |> Map.merge(source_report_reservation_capacity_status_fields(source_reports))
    |> Map.merge(source_report_precedence_fields(source_reports))
  end

  def source_report_identity_fields(source_reports) do
    %{
      "source_report_station_calendar_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_station_calendar_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_station_calendar_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_station_calendar_paths" =>
        source_report_family_identity_field(source_reports, "paths")
    }
  end

  def source_report_source_metadata_fields(source_reports) do
    %{
      "source_report_station_calendar_affected_contact_count" =>
        source_report_family_count(source_reports, "affected_contact_count"),
      "source_report_station_calendar_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_station_calendar_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_station_calendar_source_artifact_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_artifact_type_counts")
    }
  end

  def source_report_provider_contention_fields(source_reports) do
    ProviderContention.source_report_provider_contention_fields(source_reports)
  end

  def source_report_direction_fields(source_reports) do
    Direction.source_report_direction_fields(source_reports)
  end

  def source_report_reservation_capacity_status_fields(source_reports) do
    ReservationCapacityStatus.source_report_reservation_capacity_status_fields(source_reports)
  end

  def source_report_precedence_fields(source_reports) do
    Precedence.source_report_precedence_fields(source_reports)
  end
end
