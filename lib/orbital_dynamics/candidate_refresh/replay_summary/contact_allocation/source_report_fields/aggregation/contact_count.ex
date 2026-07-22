defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation.ContactCount do
  @moduledoc false

  alias __MODULE__.UniqueIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation.Values

  def capacity_pack_contact_count(summary) do
    UniqueIds.count_from_string_list_maps(
      summary,
      [
        "capacity_pack_contact_ids_by_ground_station_id",
        "capacity_pack_contact_ids_by_ground_station",
        "capacity_pack_contact_ids_by_direction",
        "capacity_pack_contact_ids_by_status",
        "capacity_pack_selected_contact_ids_by_ground_station_id",
        "capacity_pack_selected_contact_ids_by_ground_station",
        "capacity_pack_selected_contact_ids_by_direction",
        "capacity_pack_deferred_contact_ids_by_ground_station_id",
        "capacity_pack_deferred_contact_ids_by_ground_station",
        "capacity_pack_deferred_contact_ids_by_direction",
        "required_capacity_fraction_contact_ids_by_source"
      ],
      "capacity_pack_contact_count"
    )
  end

  def station_pressure_contact_count(summary) do
    UniqueIds.count_from_lists_string_and_nested_list_maps(
      summary,
      ["station_pressure_contact_ids"],
      [
        "station_pressure_contact_ids_by_ground_station_id",
        "station_pressure_contact_ids_by_ground_station",
        "station_pressure_contact_ids_by_availability",
        "station_pressure_contact_ids_by_precedence_availability",
        "station_pressure_contact_ids_by_precedence_rank",
        "station_pressure_contact_ids_by_status",
        "station_pressure_contact_ids_by_direction"
      ],
      [
        "station_pressure_contact_ids_by_direction_and_ground_station_id",
        "station_pressure_contact_ids_by_direction_and_ground_station"
      ],
      "station_pressure_contact_count"
    )
  end

  def station_pressure_review_contact_count(summary) do
    if Map.has_key?(summary, "station_pressure_review_contact_ids") do
      summary
      |> Map.get("station_pressure_review_contact_ids")
      |> UniqueIds.count_from_list()
    else
      Values.numeric_report_count(summary, "station_pressure_review_contact_count")
    end
  end

  def reservation_conflict_contact_count(summary) do
    UniqueIds.count_from_lists_string_and_nested_list_maps(
      summary,
      ["reservation_conflict_contact_ids"],
      [
        "reservation_conflict_contact_ids_by_match_status",
        "reservation_conflict_contact_ids_by_direction"
      ],
      [
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
        "reservation_conflict_contact_ids_by_direction_and_ground_station"
      ],
      "reservation_conflict_contact_count"
    )
  end
end
