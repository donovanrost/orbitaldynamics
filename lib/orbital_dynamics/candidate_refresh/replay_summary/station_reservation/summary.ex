defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary do
  @moduledoc false

  alias __MODULE__.Pressure
  alias __MODULE__.ProviderContention
  alias __MODULE__.ReservationHold
  alias __MODULE__.ReservationFields

  def summary(reservation_summary, summary_source, replay_scope) do
    affected_contact_count = summary_integer(reservation_summary, "affected_contact_count")

    provider_contention_replay = ProviderContention.fields(reservation_summary)

    reservation_review_count = summary_integer(reservation_summary, "reservation_review_count")

    reservation_hold_replay = ReservationHold.fields(reservation_summary)
    reservation_fields = ReservationFields.fields(reservation_summary)

    reservation_evidence_count =
      summary_integer(reservation_summary, "station_reservation_evidence_row_count")

    expiration_evidence_count =
      summary_integer(reservation_summary, "station_reservation_expiration_evidence_row_count")

    pressure_fields =
      Pressure.fields(
        reservation_fields,
        provider_contention_replay,
        reservation_hold_replay,
        %{
          affected_contact_count: affected_contact_count,
          reservation_review_count: reservation_review_count,
          reservation_evidence_count: reservation_evidence_count,
          expiration_evidence_count: expiration_evidence_count
        }
      )

    %{
      "model" => "artifact_only_candidate_refresh_station_reservation_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(reservation_summary, "station_reservation_report.v1"),
      "source_report_count" => summary_integer(reservation_summary, "count"),
      "source_report_row_count" => summary_integer(reservation_summary, "row_count"),
      "source_report_paths" => Map.get(reservation_summary, "paths", []),
      "affected_contact_count" => affected_contact_count,
      "reservation_review_count" => reservation_review_count,
      "station_reservation_evidence_row_count" => reservation_evidence_count,
      "station_reservation_expiration_evidence_row_count" => expiration_evidence_count,
      "trust_boundary_status" => Map.get(reservation_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(reservation_summary, "trust_boundaries", []),
      "branch_local_station_reservation_pressure" =>
        Map.get(pressure_fields, "branch_local_station_reservation_pressure"),
      "branch_local_reservation_review_pressure" =>
        Map.get(pressure_fields, "branch_local_reservation_review_pressure"),
      "branch_local_reservation_owner_pressure" =>
        Map.get(pressure_fields, "branch_local_reservation_owner_pressure"),
      "branch_local_reservation_expiration_pressure" =>
        Map.get(pressure_fields, "branch_local_reservation_expiration_pressure"),
      "branch_local_reservation_hold_pressure" =>
        Map.get(pressure_fields, "branch_local_reservation_hold_pressure"),
      "branch_local_provider_contention_pressure" =>
        Map.get(pressure_fields, "branch_local_provider_contention_pressure"),
      "branch_local_reservation_hold_import_readiness_pressure" =>
        Map.get(pressure_fields, "branch_local_reservation_hold_import_readiness_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_station_reservation_replay_summary",
        "provider_reservation" => "not_performed_by_summary",
        "station_calendar_mutation" => "not_performed_by_summary",
        "schedule_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_station_reservation_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(reservation_fields)
    |> Map.merge(provider_contention_replay)
    |> Map.merge(reservation_hold_replay)
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

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

  defp summary_integer(_summary, _field), do: 0

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
