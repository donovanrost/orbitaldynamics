defmodule OrbitalDynamics.Timeline.ProtectionSummaryPolicy do
  @moduledoc false

  def protection_decision_ids(rows, decision, field, sorted_uniq) do
    rows
    |> Enum.filter(&(&1["protection_decision"] == decision))
    |> Enum.map(& &1[field])
    |> sorted_uniq.()
  end

  def protection_category_activity_ids(rows, sorted_uniq) do
    protection_id_sets_by_field(
      rows,
      "protection_category",
      "activity_id",
      sorted_uniq
    )
  end

  def protection_id_sets_by_field(rows, group_field, id_field, sorted_uniq) do
    rows
    |> Enum.reject(&(is_nil(&1[group_field]) or is_nil(&1[id_field])))
    |> Enum.group_by(& &1[group_field], & &1[id_field])
    |> Enum.sort_by(fn {group, _ids} -> group end)
    |> Map.new(fn {group, ids} -> {group, sorted_uniq.(ids)} end)
  end

  def preservation_status_from_counts(_preserve_count, review_count) when review_count > 0,
    do: "review_required"

  def preservation_status_from_counts(preserve_count, _review_count) when preserve_count > 0,
    do: "preservation_required"

  def preservation_status_from_counts(_preserve_count, _review_count), do: "clear"
end
