defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.StationPressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.{
    StationPressureReviewCorrelation,
    StationPressureRoutingCorrelation
  }

  def fields(allocation_summary) do
    review_fields = StationPressureReviewCorrelation.fields(allocation_summary)
    routing_fields = StationPressureRoutingCorrelation.fields(allocation_summary)

    %{
      "station_pressure_contact_count" =>
        SourceReportFields.contact_allocation_station_pressure_contact_count(allocation_summary),
      "station_pressure_review_contact_count" =>
        Map.get(review_fields, "station_pressure_review_contact_count"),
      "station_pressure_review_contact_ids" =>
        Map.get(review_fields, "station_pressure_review_contact_ids"),
      "station_pressure_ground_station_counts" =>
        Map.get(routing_fields, "station_pressure_ground_station_counts", %{}),
      "station_pressure_contact_ids_by_ground_station" =>
        Map.get(routing_fields, "station_pressure_contact_ids_by_ground_station", %{}),
      "station_pressure_availability_counts" =>
        Map.get(allocation_summary, "station_pressure_availability_counts", %{}),
      "station_pressure_contact_ids_by_availability" =>
        Map.get(allocation_summary, "station_pressure_contact_ids_by_availability", %{}),
      "station_pressure_precedence_availability_counts" =>
        Map.get(allocation_summary, "station_pressure_precedence_availability_counts", %{}),
      "station_pressure_contact_ids_by_precedence_availability" =>
        Map.get(
          allocation_summary,
          "station_pressure_contact_ids_by_precedence_availability",
          %{}
        ),
      "station_pressure_precedence_rank_counts" =>
        Map.get(allocation_summary, "station_pressure_precedence_rank_counts", %{}),
      "station_pressure_contact_ids_by_precedence_rank" =>
        Map.get(allocation_summary, "station_pressure_contact_ids_by_precedence_rank", %{}),
      "station_pressure_status_counts" =>
        Map.get(allocation_summary, "station_pressure_status_counts", %{}),
      "station_pressure_contact_ids_by_status" =>
        Map.get(allocation_summary, "station_pressure_contact_ids_by_status", %{}),
      "station_pressure_direction_counts" =>
        Map.get(routing_fields, "station_pressure_direction_counts"),
      "station_pressure_contact_ids_by_direction" =>
        Map.get(routing_fields, "station_pressure_contact_ids_by_direction"),
      "station_pressure_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          routing_fields,
          "station_pressure_contact_ids_by_direction_and_ground_station"
        )
    }
  end

  def pressure?(replay) do
    (replay["station_pressure_contact_count"] || 0) > 0 or
      (replay["station_pressure_review_contact_count"] || 0) > 0 or
      (replay["station_pressure_review_contact_ids"] || []) != [] or
      Enum.any?(
        [
          "station_pressure_ground_station_counts",
          "station_pressure_contact_ids_by_ground_station",
          "station_pressure_availability_counts",
          "station_pressure_contact_ids_by_availability",
          "station_pressure_precedence_availability_counts",
          "station_pressure_contact_ids_by_precedence_availability",
          "station_pressure_precedence_rank_counts",
          "station_pressure_contact_ids_by_precedence_rank",
          "station_pressure_status_counts",
          "station_pressure_contact_ids_by_status",
          "station_pressure_direction_counts",
          "station_pressure_contact_ids_by_direction",
          "station_pressure_contact_ids_by_direction_and_ground_station"
        ],
        &(map_size(replay[&1] || %{}) > 0)
      )
  end
end
