defmodule OrbitalDynamics.OperationalReadiness.ResourceAvailabilityGate do
  @moduledoc false

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

  def build(evidence) do
    case evidence["resource_availability_pressure_count"] do
      count when is_integer(count) and count > 0 ->
        %{
          "id" => "resource_availability",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "resource availability evidence requires operator review before import"
        }
        |> Map.merge(context(evidence))

      _count ->
        nil
    end
  end

  def context(evidence) do
    resource_availability_reason_counts =
      evidence
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()

    %{
      "resource_availability_pressure_count" => evidence["resource_availability_pressure_count"],
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
      "resource_blocking_dimension_counts" => evidence["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        evidence["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        evidence["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" => evidence["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" => evidence["resource_trust_boundary_status_counts"]
    }
  end

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
end
