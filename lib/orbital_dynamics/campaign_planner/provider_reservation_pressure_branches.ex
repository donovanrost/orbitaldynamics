defmodule OrbitalDynamics.CampaignPlanner.ProviderReservationPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ScalarValues, ValueEncoding}

  def build(row, source_path, callbacks \\ default_callbacks()) do
    event = pressure_event(row, source_path, callbacks)
    contact_id = Map.get(row, "contact_id")

    if is_nil(event) or contact_id in [nil, ""] do
      []
    else
      branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
      compact_map = Keyword.fetch!(callbacks, :compact_map)

      status =
        event
        |> Map.get("provider_reservation_request_status", "review_required")
        |> branch_id_fragment.()

      [
        %{
          "id" =>
            "derived_contact_allocation_pressure_provider_reservation_#{status}_#{branch_id_fragment.(contact_id)}",
          "label" => "Derived provider reservation request pressure #{contact_id}",
          "events" => [event],
          "metadata" =>
            %{
              "derived_source" => source_path,
              "contact_id" => contact_id,
              "provider_reservation_request_status" =>
                event["provider_reservation_request_status"],
              "provider_reservation_row_scope" => event["provider_reservation_row_scope"],
              "source_window_id" => event["source_window_id"],
              "starts_at_s" => event["starts_at_s"],
              "ends_at_s" => event["ends_at_s"],
              "station_calendar_entry_id" => event["station_calendar_entry_id"],
              "station_calendar_provider_id" => event["station_calendar_provider_id"],
              "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
              "station_reservation_id" => event["station_reservation_id"],
              "station_calendar_reservation_ids" => event["station_calendar_reservation_ids"],
              "station_calendar_reserved_by" => event["station_calendar_reserved_by"],
              "station_calendar_reservation_statuses" =>
                event["station_calendar_reservation_statuses"],
              "station_reservation_expires_at_s" => event["station_reservation_expires_at_s"],
              "station_reservation_expiration_status" =>
                event["station_reservation_expiration_status"],
              "station_reservation_match_status" => event["station_reservation_match_status"]
            }
            |> compact_map.()
        }
      ]
    end
  end

  defp pressure_event(row, source_path, callbacks) do
    normalized_status_token = Keyword.fetch!(callbacks, :normalized_status_token)
    row_scope = row["_provider_reservation_row_scope"]
    request_status = normalized_status_token.(row["_provider_reservation_request_status"])
    match_status = normalized_status_token.(row["station_reservation_match_status"])

    cond do
      row_scope not in ["request", "review"] ->
        nil

      not pressure?(row_scope, request_status, match_status) ->
        nil

      true ->
        compact_map = Keyword.fetch!(callbacks, :compact_map)
        trust_boundary = Keyword.fetch!(callbacks, :trust_boundary)
        contact_id = row["contact_id"]

        %{
          "type" => "provider_reservation_request_pressure",
          "contact_id" => contact_id,
          "source_activity_id" => contact_id,
          "source_activity_ids" => List.wrap(contact_id),
          "source_window_id" => row["source_window_id"],
          "starts_at_s" => row["starts_at_s"],
          "ends_at_s" => row["ends_at_s"],
          "ground_station_id" => row["ground_station_id"] || row["station_id"],
          "direction" => row["direction"],
          "station_calendar_entry_id" => row["station_calendar_entry_id"],
          "station_calendar_provider_id" => row["station_calendar_provider_id"],
          "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
          "station_reservation_id" => row["station_reservation_id"],
          "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
          "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
          "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
          "station_reserved_by" => row["station_reserved_by"],
          "station_reservation_status" =>
            normalized_status_token.(row["station_reservation_status"]),
          "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
          "station_reservation_expiration_status" =>
            normalized_status_token.(row["station_reservation_expiration_status"]),
          "station_reservation_match_status" => match_status,
          "provider_reservation_request_status" => request_status,
          "provider_reservation_row_scope" => row_scope,
          "required_operator_action" =>
            row["required_operator_action"] || "review_provider_reservation_request",
          "derivation_reasons" => pressure_reasons(row_scope, request_status, match_status),
          "feedback_source" => source_path,
          "feedback_scope" => "contact_allocation_provider_reservation_request",
          "trust_boundary" => trust_boundary.(row),
          "assumptions" => %{
            "provider_reservation_execution" => "not_performed_by_strategy_branch",
            "schedule_mutation" => "not_performed_by_strategy_branch",
            "operator_authority" => "not_granted_by_strategy_branch"
          }
        }
        |> compact_map.()
    end
  end

  defp pressure?("review", _request_status, _match_status), do: true

  defp pressure?("request", _request_status, match_status),
    do: match_status in ["overlap", "conflict", "unmatched", "owner_mismatch"]

  defp pressure?(_row_scope, _request_status, _match_status), do: false

  defp pressure_reasons(row_scope, request_status, match_status) do
    [
      "provider_reservation_#{row_scope}",
      request_status && "provider_reservation_#{request_status}",
      match_status && "provider_reservation_match_#{match_status}"
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp default_callbacks do
    [
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      normalized_status_token: &ScalarValues.normalized_status_token/1,
      trust_boundary: &trust_boundary/1
    ]
  end

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      Map.get(row, "resource_trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
