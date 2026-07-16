defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.ContactIds do
  @moduledoc false

  def string_list_map_contact_ids(%{} = contact_ids_by_group) do
    contact_ids_by_group
    |> Enum.flat_map(fn {_group, contact_ids} -> list_value(contact_ids) end)
  end

  def string_list_map_contact_ids(_contact_ids_by_group), do: []

  def nested_string_list_map_contact_ids(%{} = contact_ids_by_outer_group) do
    contact_ids_by_outer_group
    |> Enum.flat_map(fn
      {_outer_group, %{} = contact_ids_by_inner_group} ->
        string_list_map_contact_ids(contact_ids_by_inner_group)

      {_outer_group, _contact_ids_by_inner_group} ->
        []
    end)
  end

  def nested_string_list_map_contact_ids(_contact_ids_by_outer_group), do: []

  def count_unique_contact_ids(contact_ids) do
    contact_ids
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
