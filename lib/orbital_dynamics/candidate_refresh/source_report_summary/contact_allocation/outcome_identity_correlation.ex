defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.OutcomeIdentityCorrelation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  @field_pairs [
    {"allocated_contact_count", "allocated_contact_ids"},
    {"returned_allocated_contact_count", "returned_allocated_contact_ids"},
    {"deferred_contact_count", "deferred_contact_ids"},
    {"blocked_contact_count", "blocked_contact_ids"},
    {"policy_blocked_allocated_contact_count", "policy_blocked_contact_ids"}
  ]

  def field_pairs, do: @field_pairs

  def fields(%{} = summary) do
    Enum.reduce(@field_pairs, summary, fn {count_field, ids_field}, correlated ->
      contact_ids = contact_ids(Map.get(summary, ids_field))

      correlated
      |> put_or_delete(ids_field, contact_ids)
      |> put_or_delete(
        count_field,
        correlated_count(Map.get(summary, count_field), contact_ids)
      )
    end)
  end

  def contact_ids(contact_ids) when is_list(contact_ids) do
    contact_ids
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> non_empty_list()
  end

  def contact_ids(_contact_ids), do: nil

  def correlated_count(count, contact_ids) when is_list(contact_ids) do
    if is_integer(count) and count > 0 and count >= length(contact_ids), do: count
  end

  def correlated_count(count, _contact_ids), do: count

  defp put_or_delete(map, field, nil), do: Map.delete(map, field)
  defp put_or_delete(map, field, value), do: Map.put(map, field, value)

  defp non_empty_list([]), do: nil
  defp non_empty_list(values), do: values
end
