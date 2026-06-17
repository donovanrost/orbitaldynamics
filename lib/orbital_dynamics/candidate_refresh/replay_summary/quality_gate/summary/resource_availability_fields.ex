defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.Summary.ResourceAvailabilityFields do
  @moduledoc false

  def fields(quality_gate_summary) do
    %{
      "resource_availability_pressure_count" =>
        summary_integer(quality_gate_summary, "resource_availability_pressure_count"),
      "resource_availability_reason_counts" =>
        Map.get(quality_gate_summary, "resource_availability_reason_counts", %{}),
      "resource_availability_reason_ids" =>
        Map.get(quality_gate_summary, "resource_availability_reason_ids", []),
      "station_availability_reason_ids" =>
        Map.get(quality_gate_summary, "station_availability_reason_ids", []),
      "station_availability_reason_counts" =>
        Map.get(quality_gate_summary, "station_availability_reason_counts", %{}),
      "unavailable_resource_reason_ids" =>
        Map.get(quality_gate_summary, "unavailable_resource_reason_ids", []),
      "resource_blocking_dimension_counts" =>
        Map.get(quality_gate_summary, "resource_blocking_dimension_counts", %{}),
      "blocked_contact_ids_by_blocking_dimension" =>
        Map.get(quality_gate_summary, "blocked_contact_ids_by_blocking_dimension", %{}),
      "blocked_contact_ids_by_spacecraft_id" =>
        Map.get(quality_gate_summary, "blocked_contact_ids_by_spacecraft_id", %{}),
      "blocked_contact_ids_by_status" =>
        Map.get(quality_gate_summary, "blocked_contact_ids_by_status", %{})
    }
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

  defp summary_integer(_summary, _field), do: 0
end
