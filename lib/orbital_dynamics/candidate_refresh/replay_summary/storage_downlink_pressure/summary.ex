defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary do
  @moduledoc false

  alias __MODULE__.CapacityPack
  alias __MODULE__.ResourceRouting
  alias __MODULE__.SourceReports
  alias __MODULE__.Throughput

  def summary(source_reports) do
    pressure_reports =
      Map.take(source_reports, [
        "contact_allocation_report",
        "link_capacity_report",
        "resource_projection_report"
      ])

    allocation_summary = Map.get(pressure_reports, "contact_allocation_report", %{})
    link_summary = Map.get(pressure_reports, "link_capacity_report", %{})
    projection_summary = Map.get(pressure_reports, "resource_projection_report", %{})

    source_report_replay = SourceReports.fields(pressure_reports)
    capacity_pack_replay = CapacityPack.fields(allocation_summary)
    throughput_replay = Throughput.fields(link_summary)

    resource_routing_replay =
      ResourceRouting.fields(allocation_summary, link_summary, projection_summary)

    branch_local_storage_pressure =
      ResourceRouting.storage_pressure?(resource_routing_replay)

    branch_local_capacity_adjusted_throughput_pressure =
      Throughput.capacity_adjusted_pressure?(throughput_replay)

    branch_local_actual_throughput_pressure = Throughput.actual_pressure?(throughput_replay)

    branch_local_resource_activity_pressure =
      ResourceRouting.resource_activity_pressure?(resource_routing_replay)

    capacity_pack_pressure = CapacityPack.pressure?(capacity_pack_replay)

    branch_local_downlink_pressure =
      ResourceRouting.downlink_pressure?(resource_routing_replay) or
        branch_local_capacity_adjusted_throughput_pressure or
        branch_local_actual_throughput_pressure or
        capacity_pack_pressure

    %{
      "model" => "artifact_only_candidate_refresh_storage_downlink_pressure_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.storage_downlink_pressure",
      "branch_local_storage_downlink_pressure" =>
        branch_local_storage_pressure or branch_local_downlink_pressure or
          branch_local_resource_activity_pressure,
      "branch_local_storage_pressure" => branch_local_storage_pressure,
      "branch_local_downlink_pressure" => branch_local_downlink_pressure,
      "branch_local_capacity_pack_pressure" => capacity_pack_pressure,
      "branch_local_downlink_shortfall_pressure" =>
        ResourceRouting.downlink_shortfall_pressure?(resource_routing_replay),
      "branch_local_capacity_adjusted_throughput_pressure" =>
        branch_local_capacity_adjusted_throughput_pressure,
      "branch_local_actual_throughput_pressure" => branch_local_actual_throughput_pressure,
      "branch_local_resource_activity_pressure" => branch_local_resource_activity_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" =>
          "contact_allocation_link_capacity_resource_projection_source_report_provenance_only",
        "operator_authority" => "not_granted_by_storage_downlink_pressure_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "resource_projection" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_storage_downlink_pressure_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(source_report_replay)
    |> Map.merge(resource_routing_replay)
    |> Map.merge(throughput_replay)
    |> Map.merge(capacity_pack_replay)
    |> compact_map()
  end

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
