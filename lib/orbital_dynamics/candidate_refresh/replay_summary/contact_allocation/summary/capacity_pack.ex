defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.CapacityPack do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields
  alias __MODULE__.Pressure

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.Normalization,
    only: [numeric_value: 1, summary_integer: 2]

  def fields(allocation_summary) do
    %{
      "capacity_pack_status_counts" =>
        Map.get(allocation_summary, "capacity_pack_status_counts", %{}),
      "capacity_pack_contact_status_counts" =>
        Map.get(allocation_summary, "capacity_pack_contact_status_counts", %{}),
      "capacity_pack_required_capacity_fraction" =>
        numeric_value(Map.get(allocation_summary, "capacity_pack_required_capacity_fraction")) ||
          0.0,
      "capacity_pack_selected_required_capacity_fraction" =>
        numeric_value(
          Map.get(allocation_summary, "capacity_pack_selected_required_capacity_fraction")
        ) ||
          0.0,
      "capacity_pack_deferred_required_capacity_fraction" =>
        numeric_value(
          Map.get(allocation_summary, "capacity_pack_deferred_required_capacity_fraction")
        ) ||
          0.0,
      "capacity_pack_required_capacity_fraction_by_status" =>
        Map.get(allocation_summary, "capacity_pack_required_capacity_fraction_by_status", %{}),
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        Map.get(
          allocation_summary,
          "capacity_pack_required_capacity_fraction_by_ground_station",
          %{}
        ),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
        Map.get(
          allocation_summary,
          "capacity_pack_selected_required_capacity_fraction_by_ground_station",
          %{}
        ),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
        Map.get(
          allocation_summary,
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station",
          %{}
        ),
      "capacity_pack_required_capacity_fraction_by_direction" =>
        Map.get(
          allocation_summary,
          "capacity_pack_required_capacity_fraction_by_direction",
          %{}
        ),
      "capacity_pack_selected_required_capacity_fraction_by_direction" =>
        Map.get(
          allocation_summary,
          "capacity_pack_selected_required_capacity_fraction_by_direction",
          %{}
        ),
      "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
        Map.get(
          allocation_summary,
          "capacity_pack_deferred_required_capacity_fraction_by_direction",
          %{}
        ),
      "capacity_pack_selected_contact_ids_by_ground_station" =>
        Map.get(allocation_summary, "capacity_pack_selected_contact_ids_by_ground_station", %{}),
      "capacity_pack_deferred_contact_ids_by_ground_station" =>
        Map.get(allocation_summary, "capacity_pack_deferred_contact_ids_by_ground_station", %{}),
      "capacity_pack_contact_ids_by_ground_station" =>
        Map.get(allocation_summary, "capacity_pack_contact_ids_by_ground_station", %{}),
      "capacity_pack_selected_contact_ids_by_direction" =>
        Map.get(allocation_summary, "capacity_pack_selected_contact_ids_by_direction", %{}),
      "capacity_pack_deferred_contact_ids_by_direction" =>
        Map.get(allocation_summary, "capacity_pack_deferred_contact_ids_by_direction", %{}),
      "capacity_pack_contact_ids_by_direction" =>
        Map.get(allocation_summary, "capacity_pack_contact_ids_by_direction", %{}),
      "capacity_pack_contact_ids_by_status" =>
        Map.get(allocation_summary, "capacity_pack_contact_ids_by_status", %{}),
      "capacity_pack_contact_count" => contact_count(allocation_summary),
      "reduced_capacity_pack_group_count" =>
        count_or_nil(allocation_summary, "reduced_capacity_pack_group_count"),
      "reduced_capacity_pack_status_counts" =>
        Map.get(allocation_summary, "reduced_capacity_pack_status_counts"),
      "capacity_pack_group_ids" => Map.get(allocation_summary, "capacity_pack_group_ids"),
      "capacity_pack_group_ids_by_status" =>
        Map.get(allocation_summary, "capacity_pack_group_ids_by_status"),
      "required_capacity_fraction_source_counts" =>
        Map.get(allocation_summary, "required_capacity_fraction_source_counts", %{}),
      "required_capacity_fraction_contact_ids_by_source" =>
        Map.get(allocation_summary, "required_capacity_fraction_contact_ids_by_source", %{}),
      "reduced_capacity_packed_contact_ids" =>
        Map.get(allocation_summary, "reduced_capacity_packed_contact_ids"),
      "reduced_capacity_deferred_contact_ids" =>
        Map.get(allocation_summary, "reduced_capacity_deferred_contact_ids")
    }
  end

  def pressure?(
        replay,
        allocated_contact_count,
        returned_allocated_contact_count,
        policy_blocked_allocated_contact_count
      ) do
    Pressure.pressure?(
      replay,
      allocated_contact_count,
      returned_allocated_contact_count,
      policy_blocked_allocated_contact_count
    )
  end

  def deferred_pressure?(replay) do
    Pressure.deferred_pressure?(replay)
  end

  defp contact_count(allocation_summary) do
    case SourceReportFields.contact_allocation_capacity_pack_contact_count(allocation_summary) do
      0 -> nil
      count -> count
    end
  end

  defp count_or_nil(allocation_summary, field) do
    case summary_integer(allocation_summary, field) do
      0 -> nil
      count -> count
    end
  end
end
