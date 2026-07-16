defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary.ReservationHold do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def fields(reservation_summary) do
    %{
      "reservation_hold_count" =>
        optional_summary_integer(reservation_summary, "reservation_hold_count"),
      "affected_contact_reservation_hold_count" =>
        optional_summary_integer(reservation_summary, "affected_contact_reservation_hold_count"),
      "provider_calendar_contention_hold_count" =>
        optional_summary_integer(reservation_summary, "provider_calendar_contention_hold_count"),
      "reservation_hold_review_status_counts" =>
        Map.get(reservation_summary, "reservation_hold_review_status_counts"),
      "reservation_hold_expiration_count" =>
        optional_summary_integer(reservation_summary, "reservation_hold_expiration_count"),
      "earliest_reservation_hold_expires_at_s" =>
        numeric_value(Map.get(reservation_summary, "earliest_reservation_hold_expires_at_s")),
      "reservation_hold_expiration_status_counts" =>
        Map.get(reservation_summary, "reservation_hold_expiration_status_counts"),
      "reservation_hold_status_counts" =>
        Map.get(reservation_summary, "reservation_hold_status_counts"),
      "reservation_hold_import_readiness_status_counts" =>
        Map.get(reservation_summary, "reservation_hold_import_readiness_status_counts"),
      "reservation_hold_import_classification_counts" =>
        Map.get(reservation_summary, "reservation_hold_import_classification_counts"),
      "reservation_hold_ready_for_import_count" =>
        optional_summary_integer(reservation_summary, "reservation_hold_ready_for_import_count"),
      "reservation_hold_review_required_before_import_count" =>
        optional_summary_integer(
          reservation_summary,
          "reservation_hold_review_required_before_import_count"
        ),
      "reservation_hold_no_import_required_count" =>
        optional_summary_integer(reservation_summary, "reservation_hold_no_import_required_count"),
      "reservation_hold_import_status_counts" =>
        Map.get(reservation_summary, "reservation_hold_import_status_counts"),
      "reservation_hold_required_import_action_counts" =>
        Map.get(reservation_summary, "required_import_action_counts"),
      "reservation_hold_ids" => Map.get(reservation_summary, "reservation_hold_ids"),
      "reservation_hold_ids_by_import_status" =>
        Map.get(reservation_summary, "reservation_hold_ids_by_import_status"),
      "reservation_hold_ids_by_required_import_action" =>
        Map.get(reservation_summary, "reservation_hold_ids_by_required_import_action"),
      "reservation_hold_ids_by_expiration_status" =>
        Map.get(reservation_summary, "reservation_hold_ids_by_expiration_status"),
      "reservation_hold_ids_by_status" =>
        Map.get(reservation_summary, "reservation_hold_ids_by_status"),
      "reservation_hold_ids_by_reserved_by" =>
        Map.get(reservation_summary, "reservation_hold_ids_by_reserved_by"),
      "reservation_hold_ids_by_row_type" =>
        Map.get(reservation_summary, "reservation_hold_ids_by_row_type"),
      "reservation_hold_ids_by_direction" =>
        Map.get(reservation_summary, "reservation_hold_ids_by_direction"),
      "reservation_hold_contact_ids_by_import_status" =>
        Map.get(reservation_summary, "reservation_hold_contact_ids_by_import_status"),
      "reservation_hold_contact_ids_by_expiration_status" =>
        Map.get(reservation_summary, "reservation_hold_contact_ids_by_expiration_status"),
      "reservation_hold_contact_ids_by_direction" =>
        Map.get(reservation_summary, "reservation_hold_contact_ids_by_direction"),
      "reservation_hold_review_contact_ids" =>
        Map.get(reservation_summary, "reservation_hold_review_contact_ids")
    }
  end

  def pressure?(replay) do
    (replay["reservation_hold_count"] || 0) > 0 or
      (replay["affected_contact_reservation_hold_count"] || 0) > 0 or
      (replay["provider_calendar_contention_hold_count"] || 0) > 0 or
      (replay["reservation_hold_expiration_count"] || 0) > 0 or
      not is_nil(replay["earliest_reservation_hold_expires_at_s"]) or
      map_size(replay["reservation_hold_review_status_counts"] || %{}) > 0 or
      map_size(replay["reservation_hold_expiration_status_counts"] || %{}) > 0 or
      map_size(replay["reservation_hold_status_counts"] || %{}) > 0 or
      (replay["reservation_hold_ids"] || []) != [] or
      map_size(replay["reservation_hold_ids_by_direction"] || %{}) > 0 or
      map_size(replay["reservation_hold_ids_by_expiration_status"] || %{}) > 0 or
      map_size(replay["reservation_hold_ids_by_status"] || %{}) > 0 or
      map_size(replay["reservation_hold_ids_by_reserved_by"] || %{}) > 0 or
      map_size(replay["reservation_hold_ids_by_row_type"] || %{}) > 0 or
      map_size(replay["reservation_hold_contact_ids_by_direction"] || %{}) > 0 or
      map_size(replay["reservation_hold_contact_ids_by_expiration_status"] || %{}) > 0 or
      (replay["reservation_hold_review_contact_ids"] || []) != []
  end

  def import_readiness_pressure?(replay) do
    pressure?(replay) or
      (replay["reservation_hold_review_required_before_import_count"] || 0) > 0 or
      map_size(replay["reservation_hold_import_readiness_status_counts"] || %{}) > 0 or
      map_size(replay["reservation_hold_import_status_counts"] || %{}) > 0 or
      map_size(replay["reservation_hold_required_import_action_counts"] || %{}) > 0 or
      map_size(replay["reservation_hold_ids_by_import_status"] || %{}) > 0 or
      map_size(replay["reservation_hold_ids_by_required_import_action"] || %{}) > 0 or
      map_size(replay["reservation_hold_ids_by_direction"] || %{}) > 0 or
      map_size(replay["reservation_hold_contact_ids_by_import_status"] || %{}) > 0 or
      map_size(replay["reservation_hold_contact_ids_by_direction"] || %{}) > 0
  end

  def station_reservation_pressure?(replay) do
    (replay["reservation_hold_count"] || 0) > 0 or
      (replay["reservation_hold_ids"] || []) != [] or
      map_size(replay["reservation_hold_import_status_counts"] || %{}) > 0 or
      map_size(replay["reservation_hold_required_import_action_counts"] || %{}) > 0 or
      map_size(replay["reservation_hold_ids_by_direction"] || %{}) > 0 or
      map_size(replay["reservation_hold_contact_ids_by_direction"] || %{}) > 0
  end

  defp optional_summary_integer(summary, field) do
    if Map.has_key?(summary, field) do
      summary_integer(summary, field)
    end
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)
end
