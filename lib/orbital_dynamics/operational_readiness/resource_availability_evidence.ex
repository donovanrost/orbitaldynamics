defmodule OrbitalDynamics.OperationalReadiness.ResourceAvailabilityEvidence do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.EvidenceNormalization

  defp stable_sorted_evidence_values(values) do
    values
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def stable_id_array_map(%{} = map) do
    map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      key = normalized_evidence_string(key)
      ids = values |> list_value() |> stable_sorted_evidence_values()

      if key && ids != [] do
        Map.put(acc, key, ids)
      else
        acc
      end
    end)
  end

  def stable_id_array_map(_map), do: %{}

  def merge_string_list_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = map, acc ->
        map
        |> stable_id_array_map()
        |> Enum.reduce(acc, fn {key, ids}, inner_acc ->
          Map.update(inner_acc, key, ids, fn current ->
            (current ++ ids)
            |> Enum.uniq()
            |> Enum.sort()
          end)
        end)

      _map, acc ->
        acc
    end)
  end

  def resource_availability_reason_counts(review_rows, import_rows) do
    review_rows
    |> source_resource_evidence_rows(import_rows)
    |> Enum.flat_map(&resource_availability_reasons/1)
    |> Enum.frequencies()
  end

  def resource_blocking_dimension_counts(review_rows, import_rows) do
    review_rows
    |> source_resource_evidence_rows(import_rows)
    |> Enum.flat_map(&resource_blocking_dimensions/1)
    |> Enum.frequencies()
  end

  def resource_blocked_contact_id_map(review_rows, import_rows, map_field, group_field) do
    review_rows
    |> source_resource_evidence_rows(import_rows)
    |> Enum.flat_map(fn row ->
      resource_blocked_contact_id_maps(row, map_field) ++
        [resource_blocked_contact_id_pair_map(row, group_field)]
    end)
    |> merge_string_list_maps()
  end

  def resource_provenance_counts(review_rows, import_rows, field) do
    review_rows
    |> source_resource_evidence_rows(import_rows)
    |> Enum.map(&resource_provenance_map/1)
    |> Enum.filter(&is_map/1)
    |> Enum.map(&Map.get(&1, field))
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp source_resource_evidence_rows(review_rows, _import_rows) when review_rows != [],
    do: review_rows

  defp source_resource_evidence_rows(_review_rows, import_rows), do: import_rows

  defp resource_provenance_map(%{} = row) do
    [
      row["source_resource_projection"],
      get_in(row, ["source_review_row", "source_resource_projection"]),
      row["source_resource_suppression"],
      get_in(row, ["source_contact_allocation", "source_resource_suppression"]),
      get_in(row, ["source_review_row", "source_resource_suppression"]),
      get_in(row, [
        "source_review_row",
        "source_contact_allocation",
        "source_resource_suppression"
      ]),
      row["source_contact_allocation"],
      get_in(row, ["source_review_row", "source_contact_allocation"]),
      row,
      row["source_review_row"]
    ]
    |> Enum.find(&is_map/1)
  end

  defp resource_availability_reasons(row) do
    row
    |> resource_evidence_maps()
    |> Enum.flat_map(fn evidence ->
      list_value(evidence["resource_pressure_types"]) ++
        [
          evidence["first_resource_pressure_kind"],
          evidence["allocation_reason"],
          evidence["suppressed_reason"],
          evidence["resource_effect_reason"]
        ]
    end)
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(&(&1 in resource_availability_reasons()))
    |> Enum.uniq()
  end

  defp resource_blocking_dimensions(row) do
    row
    |> resource_evidence_maps()
    |> Enum.map(&Map.get(&1, "resource_blocking_dimension"))
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp resource_blocked_contact_id_maps(%{} = row, field) do
    [row, row["source_review_row"]]
    |> Enum.map(fn
      %{} = evidence -> Map.get(evidence, field)
      _evidence -> nil
    end)
    |> Enum.filter(&is_map/1)
  end

  defp resource_blocked_contact_id_maps(_row, _field), do: []

  defp resource_blocked_contact_id_pair_map(row, group_field) do
    row
    |> resource_evidence_maps()
    |> Enum.reduce(%{}, fn evidence, acc ->
      group = evidence |> Map.get(group_field) |> normalized_evidence_string()
      contact_id = resource_blocked_contact_id(evidence)

      if group && contact_id do
        Map.update(acc, group, [contact_id], &[contact_id | &1])
      else
        acc
      end
    end)
    |> stable_id_array_map()
  end

  defp resource_blocked_contact_id(%{} = evidence) do
    [
      evidence["contact_id"],
      evidence["activity_id"],
      evidence["candidate_activity_id"],
      evidence["id"]
    ]
    |> Enum.find_value(&normalized_evidence_string/1)
  end

  defp resource_evidence_maps(%{} = row) do
    [
      row,
      row["source_review_row"],
      row["source_resource_projection"],
      row["source_resource_suppression"],
      get_in(row, ["source_contact_allocation", "source_resource_suppression"]),
      row["source_contact_allocation"],
      row["source_contact_suppression"],
      get_in(row, ["source_review_row", "source_resource_projection"]),
      get_in(row, ["source_review_row", "source_resource_suppression"]),
      get_in(row, [
        "source_review_row",
        "source_contact_allocation",
        "source_resource_suppression"
      ]),
      get_in(row, ["source_review_row", "source_contact_allocation"]),
      get_in(row, ["source_review_row", "source_contact_suppression"])
    ]
    |> Enum.filter(&is_map/1)
  end

  defp resource_evidence_maps(_row), do: []

  defp resource_availability_reasons do
    ~w(
      antenna_unavailable
      activity_type_incompatible_with_resource_summary
      activity_type_suppressed_by_resource_summary
      ground_station_capacity_zero
      ground_station_reduced_capacity_insufficient
      ground_station_reserved
      ground_station_unavailable
      payload_unavailable
      spacecraft_degraded_payload_unavailable
      spacecraft_unavailable
    )
  end

  defp list_value(value), do: EvidenceNormalization.list_value(value)

  defp normalized_evidence_string(value),
    do: EvidenceNormalization.normalized_evidence_string(value)
end
