defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceContactAllocationReplayRisk do
  @moduledoc false

  def reservation_conflict(replay_summary) do
    reservation_ids_by_match_status =
      Map.get(replay_summary, "reservation_conflict_reservation_ids_by_match_status", %{})

    replay_summary
    |> Map.get("reservation_conflict_contact_ids_by_match_status", %{})
    |> Enum.flat_map(fn {match_status, contact_ids} ->
      reservation_ids = Map.get(reservation_ids_by_match_status, match_status, [])

      contact_ids
      |> List.wrap()
      |> Enum.with_index()
      |> Enum.map(fn {contact_id, index} ->
        reservation_id = Enum.at(reservation_ids, index) || List.first(reservation_ids)
        expiration_status = reservation_expiration_status(replay_summary, contact_id)

        %{
          "type" => "downlink_completion_gap",
          "severity" => "medium",
          "reason" =>
            "candidate source contact allocation replay reports station reservation conflict for contact #{contact_id}",
          "contact_id" => contact_id,
          "source_activity_id" => contact_id,
          "source_activity_ids" => List.wrap(contact_id),
          "station_reservation_id" => reservation_id,
          "station_reservation_match_status" => match_status,
          "station_reservation_expiration_status" => expiration_status,
          "feedback_source" => "candidate_source.contact_allocation_replay_summary",
          "feedback_scope" => "contact_allocation",
          "derivation_reasons" => ["contact_allocation_reservation_conflict"]
        }
        |> compact_map()
      end)
    end)
  end

  def provider_reservation(replay_summary) do
    provider_review_risks(replay_summary) ++ expired_or_missing_request_risks(replay_summary)
  end

  defp provider_review_risks(replay_summary) do
    replay_summary
    |> Map.get("provider_reservation_review_contact_ids_by_match_status", %{})
    |> Enum.flat_map(fn {match_status, contact_ids} ->
      contact_ids
      |> List.wrap()
      |> Enum.map(fn contact_id ->
        expiration_status = reservation_expiration_status(replay_summary, contact_id)

        %{
          "type" => "provider_reservation_request_review",
          "severity" => "high",
          "reason" =>
            "candidate source contact allocation replay reports provider reservation review for contact #{contact_id}",
          "contact_id" => contact_id,
          "source_activity_id" => contact_id,
          "source_activity_ids" => List.wrap(contact_id),
          "station_reservation_match_status" => match_status,
          "station_reservation_expiration_status" => expiration_status,
          "provider_reservation_request_status" => "review_required",
          "provider_reservation_row_scope" => "review",
          "feedback_source" => "candidate_source.contact_allocation_replay_summary",
          "feedback_scope" => "contact_allocation_provider_reservation_request"
        }
        |> compact_map()
      end)
    end)
  end

  defp expired_or_missing_request_risks(replay_summary) do
    replay_summary
    |> Map.get("provider_reservation_request_contact_ids_by_match_status", %{})
    |> Enum.flat_map(fn {match_status, contact_ids} ->
      contact_ids
      |> List.wrap()
      |> Enum.flat_map(fn contact_id ->
        case reservation_expiration_status(replay_summary, contact_id) do
          expiration_status when expiration_status in ["expired", "missing"] ->
            [
              %{
                "type" => "provider_reservation_request_review",
                "severity" => "high",
                "reason" =>
                  "candidate source contact allocation replay reports #{expiration_status} reservation evidence for request-ready provider contact #{contact_id}",
                "contact_id" => contact_id,
                "source_activity_id" => contact_id,
                "source_activity_ids" => List.wrap(contact_id),
                "station_reservation_match_status" => match_status,
                "station_reservation_expiration_status" => expiration_status,
                "provider_reservation_request_status" => "request_ready",
                "provider_reservation_row_scope" => "request",
                "required_operator_action" => "review_provider_reservation_request",
                "feedback_source" => "candidate_source.contact_allocation_replay_summary",
                "feedback_scope" => "contact_allocation_provider_reservation_request"
              }
            ]

          _status ->
            []
        end
      end)
    end)
  end

  defp reservation_expiration_status(replay_summary, contact_id) do
    replay_summary
    |> Map.get("station_reservation_contact_ids_by_expiration_status", %{})
    |> Enum.find_value(fn {status, contact_ids} ->
      if contact_id in List.wrap(contact_ids), do: status
    end)
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
