defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewProviderContentionGroupRowFields do
  @moduledoc false

  def fields(%{} = row) do
    %{
      "id" => row["subject_id"] || row["id"],
      "provider_calendar_contention_status" => row["provider_calendar_contention_status"],
      "ground_station_id" => row["ground_station_id"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "entry_count" => row["provider_calendar_contention_entry_count"] || row["entry_count"],
      "entry_ids" => row["provider_calendar_contention_entry_ids"] || row["entry_ids"],
      "provider_ids" => row["provider_calendar_contention_provider_ids"] || row["provider_ids"],
      "provider_entry_ids" =>
        row["provider_calendar_contention_provider_entry_ids"] || row["provider_entry_ids"],
      "availabilities" =>
        row["provider_calendar_contention_availabilities"] || row["availabilities"],
      "directions" => row["provider_calendar_contention_directions"] || row["directions"],
      "reservation_ids" =>
        row["provider_calendar_contention_reservation_ids"] || row["reservation_ids"],
      "reserved_by" => row["provider_calendar_contention_reserved_by"] || row["reserved_by"],
      "reservation_statuses" =>
        row["provider_calendar_contention_reservation_statuses"] || row["reservation_statuses"],
      "trust_boundary_statuses" =>
        row["provider_calendar_contention_trust_boundary_statuses"] ||
          row["trust_boundary_statuses"],
      "source_station_calendar_entries" => row["source_station_calendar_entries"]
    }
  end
end
