defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  @capacity_pack_fields [
    "contention_group_id",
    "group_id",
    "ground_station_id",
    "capacity_fraction",
    "used_capacity_fraction",
    "unused_capacity_fraction",
    "input_contact_ids",
    "selected_contact_ids",
    "selected_contact_id",
    "capacity_packed_contact_ids",
    "deferred_contact_ids",
    "capacity_requirement_rows",
    "pack_status",
    "source_contention_recommendation",
    "trust_boundary",
    "provenance"
  ]

  def source(%{"source_contact_allocation" => %{} = source}) when map_size(source) > 0,
    do: {source, "source_contact_allocation"}

  def source(row), do: {row, "contact_allocation_review"}

  def review_row?(row) do
    (row["source_review_type"] == "contact_allocation_review" or
       row["review_type"] == "contact_allocation_review" or
       row["import_action"] == "review_contact_allocation") and
      row["contact_id"] not in [nil, ""] and
      (row["allocation_status"] not in [nil, ""] or
         row["effective_allocation_status"] not in [nil, ""])
  end

  def capacity_pack_source(row), do: capacity_pack_source(row, callbacks())

  def capacity_pack_source(
        %{"source_contact_allocation_capacity_pack" => %{} = source} = row,
        callbacks
      )
      when map_size(source) > 0 do
    {capacity_pack_row(source, row, callbacks), "source_contact_allocation_capacity_pack"}
  end

  def capacity_pack_source(row, callbacks),
    do: {capacity_pack_row(row, row, callbacks), "contact_allocation_capacity_pack_review"}

  def capacity_pack_row(source, row), do: capacity_pack_row(source, row, callbacks())

  def capacity_pack_row(source, row, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    put_default_if_present = Keyword.fetch!(callbacks, :put_default_if_present)

    Enum.reduce(@capacity_pack_fields, stringify_keys.(source), fn field, acc ->
      put_default_if_present.(acc, field, row[field])
    end)
  end

  def capacity_pack_review_row?(row) do
    (row["source_review_type"] == "contact_allocation_capacity_pack_review" or
       row["review_type"] == "contact_allocation_capacity_pack_review" or
       row["import_action"] == "review_contact_allocation_capacity_pack") and
      row["deferred_contact_ids"] not in [nil, []]
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      put_default_if_present: &put_default_if_present/3
    ]
  end

  defp put_default_if_present(map, _field, value) when value in [nil, "", [], %{}], do: map

  defp put_default_if_present(map, field, value) do
    case Map.get(map, field) do
      existing when existing in [nil, ""] -> Map.put(map, field, value)
      _existing -> map
    end
  end
end
