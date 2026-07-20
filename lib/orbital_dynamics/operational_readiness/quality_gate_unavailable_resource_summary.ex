defmodule OrbitalDynamics.OperationalReadiness.QualityGateUnavailableResourceSummary do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.EvidenceNormalization
  alias OrbitalDynamics.OperationalReadiness.ResourceAvailabilityEvidence

  @schema_contract "operational_quality_gate_unavailable_resource_summary.v1"

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

  def build(quality_gate_report) do
    resource_rows = quality_gate_report |> rows() |> resource_availability_rows()
    resource_availability_counts = resource_availability_reason_counts(resource_rows)
    unavailable_counts = unavailable_resource_reason_counts(resource_rows)
    station_counts = station_availability_reason_counts(resource_availability_counts)
    quality_gate_row_ids_by_status = quality_gate_row_ids_by_status(resource_rows)

    blocked_contact_ids_by_blocking_dimension =
      blocked_contact_ids(resource_rows, "resource_blocked_contact_ids_by_blocking_dimension")

    blocked_contact_ids_by_spacecraft_id =
      blocked_contact_ids(resource_rows, "resource_blocked_contact_ids_by_spacecraft_id")

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_quality_gate_unavailable_resource_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => quality_gate_report["source_artifact_type"],
      "source_artifact_id" => quality_gate_report["source_artifact_id"],
      "source_quality_gate_report_id" => quality_gate_report["report_id"],
      "source_readiness_report_id" => quality_gate_report["source_readiness_report_id"],
      "resource_availability_row_count" => length(resource_rows),
      "unavailable_resource_row_count" => unavailable_resource_row_count(resource_rows),
      "unavailable_resource_pressure_count" =>
        EvidenceNormalization.map_value_count(unavailable_counts),
      "unavailable_resource_reason_counts" => unavailable_counts,
      "unavailable_resource_reason_ids" => sorted_count_keys(unavailable_counts),
      "station_availability_reason_counts" => station_counts,
      "station_availability_reason_ids" => sorted_count_keys(station_counts),
      "resource_blocking_dimension_counts" =>
        resource_rows
        |> Enum.map(&Map.get(&1, "resource_blocking_dimension_counts"))
        |> merge_positive_count_maps(),
      "blocked_contact_ids_by_blocking_dimension" => blocked_contact_ids_by_blocking_dimension,
      "blocked_contact_ids_by_spacecraft_id" => blocked_contact_ids_by_spacecraft_id,
      "blocked_contact_ids_by_status" => blocked_contact_ids_by_status(resource_rows),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_ids_by_status" => quality_gate_ids_by(resource_rows, "status"),
      "review_required_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("review_required", []),
      "blocked_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("blocked", []),
      "resource_availability_gate_ids" =>
        resource_rows
        |> Enum.map(& &1["gate_id"])
        |> stable_sorted_ids(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_unavailable_resource_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_unavailable_resource_summary_routes_only",
        "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
      ]
    }
    |> compact_map()
  end

  defp rows(artifact), do: EvidenceNormalization.rows(artifact)

  defp resource_availability_rows(rows) do
    Enum.filter(rows, &(&1["gate_id"] == "resource_availability"))
  end

  defp unavailable_resource_reason_counts(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()
      |> Map.filter(fn {reason, _count} -> reason in @unavailable_resource_reasons end)
    end)
    |> merge_positive_count_maps()
  end

  defp resource_availability_reason_counts(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()
    end)
    |> merge_positive_count_maps()
  end

  defp unavailable_resource_row_count(rows) do
    Enum.count(rows, fn row ->
      row
      |> Map.get("unavailable_resource_reason_ids", [])
      |> EvidenceNormalization.list_value()
      |> Enum.any?()
    end)
  end

  defp merge_positive_count_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = counts, acc ->
        counts
        |> positive_count_map()
        |> Enum.reduce(acc, fn {key, count}, inner_acc ->
          Map.update(inner_acc, key, count, &(&1 + count))
        end)

      _counts, acc ->
        acc
    end)
  end

  defp blocked_contact_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> ResourceAvailabilityEvidence.merge_string_list_maps()
  end

  defp blocked_contact_ids_by_status(rows) do
    Enum.reduce(rows, %{}, fn row, acc ->
      status = EvidenceNormalization.normalized_evidence_string(row["status"])
      ids = row_blocked_contact_ids(row)

      if status && ids != [] do
        Map.update(acc, status, ids, fn current ->
          (current ++ ids)
          |> Enum.uniq()
          |> Enum.sort()
        end)
      else
        acc
      end
    end)
  end

  defp row_blocked_contact_ids(row) do
    [
      Map.get(row, "resource_blocked_contact_ids_by_blocking_dimension"),
      Map.get(row, "resource_blocked_contact_ids_by_spacecraft_id")
    ]
    |> ResourceAvailabilityEvidence.merge_string_list_maps()
    |> Map.values()
    |> List.flatten()
    |> stable_sorted_ids()
  end

  defp positive_count_map(%{} = counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value > 0 end)
    |> Map.new()
  end

  defp positive_count_map(_counts), do: %{}

  defp sorted_count_keys(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> stable_sorted_ids()
  end

  defp station_availability_reason_counts(counts) when is_map(counts) do
    counts
    |> positive_count_map()
    |> Map.filter(fn {reason, _count} -> reason in @station_availability_reasons end)
  end

  defp quality_gate_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["gate_id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp quality_gate_row_ids_by_status(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "status"), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
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
