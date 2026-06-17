defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary do
  @moduledoc false

  alias __MODULE__.AllocationFields
  alias __MODULE__.CapacityPack
  alias __MODULE__.Pressure
  alias __MODULE__.ProviderReservation
  alias __MODULE__.ReservationConflict
  alias __MODULE__.StationPressure
  alias __MODULE__.StationReservation

  import __MODULE__.Normalization,
    only: [
      compact_map: 1,
      non_empty_map: 1,
      source_report_summary_contract: 2,
      summary_integer: 2
    ]

  def summary(
        allocation_summary,
        summary_source,
        replay_scope
      ) do
    allocation_fields = AllocationFields.fields(allocation_summary)
    capacity_pack_replay = CapacityPack.fields(allocation_summary)

    station_pressure_replay =
      StationPressure.fields(allocation_summary)

    reservation_conflict_replay =
      ReservationConflict.fields(allocation_summary)

    station_reservation_replay =
      StationReservation.fields(allocation_summary)

    provider_reservation_replay =
      ProviderReservation.fields(allocation_summary)

    source_summary_model_counts =
      allocation_summary
      |> Map.get("source_summary_model_counts", %{})
      |> non_empty_map()

    source_summary_schema_contract_counts =
      allocation_summary
      |> Map.get("source_summary_schema_contract_counts", %{})
      |> non_empty_map()

    source_artifact_type_counts =
      allocation_summary
      |> Map.get("source_artifact_type_counts", %{})
      |> non_empty_map()

    contact_allocation_summary_schema_contract =
      Map.get(allocation_summary, "contact_allocation_summary_schema_contract")

    station_pressure_summary_schema_contract =
      Map.get(allocation_summary, "station_pressure_summary_schema_contract")

    reservation_conflict_summary_schema_contract =
      Map.get(allocation_summary, "reservation_conflict_summary_schema_contract")

    capacity_pack_summary_schema_contract =
      Map.get(allocation_summary, "capacity_pack_summary_schema_contract")

    source_report_paths = Map.get(allocation_summary, "paths") || []

    capacity_pack_pressure =
      CapacityPack.pressure?(
        capacity_pack_replay,
        Map.get(allocation_fields, :allocated_contact_count),
        Map.get(allocation_fields, :returned_allocated_contact_count),
        Map.get(allocation_fields, :policy_blocked_allocated_contact_count)
      )

    pressure_fields =
      allocation_fields
      |> Map.merge(%{
        capacity_pack_replay: capacity_pack_replay,
        station_pressure_replay: station_pressure_replay,
        reservation_conflict_replay: reservation_conflict_replay,
        station_reservation_replay: station_reservation_replay,
        provider_reservation_replay: provider_reservation_replay,
        capacity_pack_pressure: capacity_pack_pressure
      })
      |> Pressure.fields()

    %{
      "model" => "artifact_only_candidate_refresh_contact_allocation_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(allocation_summary, "contact_allocation_report.v1"),
      "source_report_count" => summary_integer(allocation_summary, "count"),
      "source_report_row_count" => summary_integer(allocation_summary, "row_count"),
      "source_report_paths" => source_report_paths,
      "source_summary_model_counts" => source_summary_model_counts,
      "source_summary_schema_contract_counts" => source_summary_schema_contract_counts,
      "source_artifact_type_counts" => source_artifact_type_counts,
      "contact_allocation_summary_schema_contract" => contact_allocation_summary_schema_contract,
      "station_pressure_summary_schema_contract" => station_pressure_summary_schema_contract,
      "reservation_conflict_summary_schema_contract" =>
        reservation_conflict_summary_schema_contract,
      "capacity_pack_summary_schema_contract" => capacity_pack_summary_schema_contract,
      "trust_boundary_status" => Map.get(allocation_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(allocation_summary, "trust_boundaries", []),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_contact_allocation_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_allocation_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(AllocationFields.replay_fields(allocation_fields))
    |> Map.merge(capacity_pack_replay)
    |> Map.merge(station_pressure_replay)
    |> Map.merge(reservation_conflict_replay)
    |> Map.merge(station_reservation_replay)
    |> Map.merge(provider_reservation_replay)
    |> Map.merge(pressure_fields)
    |> compact_map()
  end
end
