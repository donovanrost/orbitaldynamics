defmodule OrbitalDynamics.OperationalReadiness.QualityGateRow do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.AdapterBoundaryGate
  alias OrbitalDynamics.OperationalReadiness.CadenceImportGate
  alias OrbitalDynamics.OperationalReadiness.OperatorTrainingGate
  alias OrbitalDynamics.OperationalReadiness.ResourceAvailabilityEvidence
  alias OrbitalDynamics.OperationalReadiness.SourceIdentity

  @unavailable_resource_reasons ~w(
    antenna_unavailable
    payload_unavailable
    spacecraft_degraded_payload_unavailable
    spacecraft_unavailable
  )

  @station_availability_reasons ~w(
    ground_station_capacity_zero
    ground_station_reduced_capacity_insufficient
    ground_station_reserved
    ground_station_unavailable
  )

  def build(gate, readiness_report, rank) do
    %{
      "id" =>
        SourceIdentity.quality_gate_row_id(
          readiness_report["source_artifact_type"],
          readiness_report["source_artifact_id"],
          gate["id"],
          rank
        ),
      "rank" => rank,
      "gate_id" => gate["id"],
      "status" => gate["status"],
      "classification" => gate["classification"],
      "reason" => gate["reason"],
      "analysis_mode" => gate["analysis_mode"],
      "analysis_mode_source" => gate["analysis_mode_source"],
      "source_operational_readiness_gate" => gate
    }
    |> Map.merge(context(gate))
    |> compact_map()
  end

  defp context(%{"id" => "resource_availability"} = gate) do
    resource_availability_reason_counts =
      gate
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()

    %{
      "resource_availability_pressure_count" => gate["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => resource_availability_reason_counts,
      "resource_availability_reason_ids" =>
        stable_sorted_ids(Map.keys(resource_availability_reason_counts)),
      "station_availability_reason_ids" =>
        reason_ids(resource_availability_reason_counts, @station_availability_reasons),
      "station_availability_reason_counts" =>
        Map.filter(resource_availability_reason_counts, fn {reason, _count} ->
          reason in @station_availability_reasons
        end),
      "unavailable_resource_reason_ids" =>
        reason_ids(resource_availability_reason_counts, @unavailable_resource_reasons),
      "resource_blocking_dimension_counts" =>
        gate
        |> Map.get("resource_blocking_dimension_counts", %{})
        |> positive_count_map(),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        gate
        |> Map.get("resource_blocked_contact_ids_by_blocking_dimension", %{})
        |> ResourceAvailabilityEvidence.stable_id_array_map(),
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        gate
        |> Map.get("resource_blocked_contact_ids_by_spacecraft_id", %{})
        |> ResourceAvailabilityEvidence.stable_id_array_map(),
      "resource_source_quality_counts" =>
        gate
        |> Map.get("resource_source_quality_counts", %{})
        |> positive_count_map(),
      "resource_trust_boundary_status_counts" =>
        gate
        |> Map.get("resource_trust_boundary_status_counts", %{})
        |> positive_count_map()
    }
  end

  defp context(%{"id" => "cadence_import"} = gate), do: CadenceImportGate.context(gate)

  defp context(%{"id" => "adapter_boundary"} = gate), do: AdapterBoundaryGate.context(gate)

  defp context(%{"id" => "operator_training"} = gate),
    do: OperatorTrainingGate.context(gate)

  defp context(_gate), do: %{}

  defp positive_count_map(%{} = counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value > 0 end)
    |> Map.new()
  end

  defp positive_count_map(_counts), do: %{}

  defp reason_ids(counts, accepted_reasons) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in accepted_reasons))
    |> stable_sorted_ids()
  end

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
