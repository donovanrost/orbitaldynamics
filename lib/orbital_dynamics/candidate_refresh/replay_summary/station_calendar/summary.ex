defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.Summary do
  @moduledoc false

  alias __MODULE__.Direction
  alias __MODULE__.ProviderContention
  alias __MODULE__.Precedence
  alias __MODULE__.ReservationCapacityStatus

  def summary(station_summary, summary_source, replay_scope) do
    affected_contact_count = summary_integer(station_summary, "affected_contact_count")

    source_summary_model_counts =
      Map.get(station_summary, "source_summary_model_counts", %{}) |> non_empty_map()

    source_summary_schema_contract_counts =
      Map.get(station_summary, "source_summary_schema_contract_counts", %{})
      |> non_empty_map()

    source_artifact_type_counts =
      Map.get(station_summary, "source_artifact_type_counts", %{}) |> non_empty_map()

    provider_contention_replay = ProviderContention.fields(station_summary)

    reservation_capacity_status_replay = ReservationCapacityStatus.fields(station_summary)

    reservation_capacity_status_pressure =
      ReservationCapacityStatus.pressure?(reservation_capacity_status_replay)

    reservation_capacity_status_availability_pressure =
      ReservationCapacityStatus.availability_pressure?(reservation_capacity_status_replay)

    precedence_replay = Precedence.fields(station_summary)
    precedence_pressure = Precedence.pressure?(precedence_replay)

    provider_contention_pressure = ProviderContention.pressure?(provider_contention_replay)

    direction_replay = Direction.fields(station_summary)
    direction_pressure = Direction.pressure?(direction_replay)
    direction_affected_contact_pressure = Direction.affected_contact_pressure?(direction_replay)

    %{
      "model" => "artifact_only_candidate_refresh_station_calendar_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(station_summary, "station_calendar_report.v1"),
      "source_report_count" => summary_integer(station_summary, "count"),
      "source_report_row_count" => summary_integer(station_summary, "row_count"),
      "source_report_paths" => Map.get(station_summary, "paths", []),
      "source_summary_model_counts" => source_summary_model_counts,
      "source_summary_schema_contract_counts" => source_summary_schema_contract_counts,
      "source_artifact_type_counts" => source_artifact_type_counts,
      "affected_contact_count" => affected_contact_count,
      "trust_boundary_status" => Map.get(station_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(station_summary, "trust_boundaries", []),
      "branch_local_station_calendar_pressure" =>
        affected_contact_count > 0 or provider_contention_pressure or
          reservation_capacity_status_pressure or precedence_pressure or direction_pressure,
      "branch_local_affected_contact_pressure" =>
        affected_contact_count > 0 or reservation_capacity_status_pressure or
          precedence_pressure or direction_affected_contact_pressure,
      "branch_local_provider_contention_pressure" => provider_contention_pressure,
      "branch_local_station_availability_pressure" =>
        reservation_capacity_status_availability_pressure or precedence_pressure or
          ProviderContention.availability_pressure?(provider_contention_replay),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_station_calendar_replay_summary",
        "station_calendar_mutation" => "not_performed_by_summary",
        "schedule_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_station_calendar_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(direction_replay)
    |> Map.merge(reservation_capacity_status_replay)
    |> Map.merge(precedence_replay)
    |> Map.merge(provider_contention_replay)
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

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
