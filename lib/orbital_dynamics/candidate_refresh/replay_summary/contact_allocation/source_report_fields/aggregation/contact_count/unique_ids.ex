defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation.ContactCount.UniqueIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation.Values

  def count_from_string_list_maps(summary, fields, fallback_field) do
    contact_id_maps =
      fields
      |> Enum.map(&Map.get(summary, &1))
      |> Enum.filter(&is_map/1)

    case contact_id_maps do
      [] ->
        Values.numeric_report_count(summary, fallback_field)

      maps ->
        maps
        |> Enum.flat_map(&string_list_map_contact_ids/1)
        |> count_unique_contact_ids()
    end
  end

  def count_from_string_and_nested_list_maps(
        summary,
        flat_fields,
        nested_fields,
        fallback_field
      ) do
    flat_contact_id_maps =
      flat_fields
      |> Enum.map(&Map.get(summary, &1))
      |> Enum.filter(&is_map/1)

    nested_contact_id_maps =
      nested_fields
      |> Enum.map(&Map.get(summary, &1))
      |> Enum.filter(&is_map/1)

    cond do
      flat_contact_id_maps != [] or nested_contact_id_maps != [] ->
        flat_contact_ids =
          flat_contact_id_maps
          |> Enum.flat_map(&string_list_map_contact_ids/1)

        nested_contact_ids =
          nested_contact_id_maps
          |> Enum.flat_map(&nested_string_list_map_contact_ids/1)

        flat_contact_ids
        |> Kernel.++(nested_contact_ids)
        |> count_unique_contact_ids()

      true ->
        Values.numeric_report_count(summary, fallback_field)
    end
  end

  def count_from_lists_string_and_nested_list_maps(
        summary,
        list_fields,
        flat_fields,
        nested_fields,
        fallback_field
      ) do
    contact_id_lists =
      list_fields
      |> Enum.filter(&Map.has_key?(summary, &1))
      |> Enum.map(&Map.get(summary, &1))

    flat_contact_id_maps =
      flat_fields
      |> Enum.filter(&Map.has_key?(summary, &1))
      |> Enum.map(&Map.get(summary, &1))

    nested_contact_id_maps =
      nested_fields
      |> Enum.filter(&Map.has_key?(summary, &1))
      |> Enum.map(&Map.get(summary, &1))

    cond do
      contact_id_lists != [] or flat_contact_id_maps != [] or nested_contact_id_maps != [] ->
        list_contact_ids =
          contact_id_lists
          |> Enum.flat_map(&list_value/1)

        flat_contact_ids =
          flat_contact_id_maps
          |> Enum.flat_map(&string_list_map_contact_ids/1)

        nested_contact_ids =
          nested_contact_id_maps
          |> Enum.flat_map(&nested_string_list_map_contact_ids/1)

        list_contact_ids
        |> Kernel.++(flat_contact_ids)
        |> Kernel.++(nested_contact_ids)
        |> count_unique_contact_ids()

      true ->
        Values.numeric_report_count(summary, fallback_field)
    end
  end

  def count_from_list(values) do
    values
    |> list_value()
    |> count_unique_contact_ids()
  end

  defp string_list_map_contact_ids(%{} = contact_ids_by_group) do
    contact_ids_by_group
    |> Enum.flat_map(fn {_group, contact_ids} -> list_value(contact_ids) end)
  end

  defp string_list_map_contact_ids(_contact_ids_by_group), do: []

  defp nested_string_list_map_contact_ids(%{} = contact_ids_by_outer_group) do
    contact_ids_by_outer_group
    |> Enum.flat_map(fn
      {_outer_group, %{} = contact_ids_by_inner_group} ->
        string_list_map_contact_ids(contact_ids_by_inner_group)

      {_outer_group, _contact_ids_by_inner_group} ->
        []
    end)
  end

  defp nested_string_list_map_contact_ids(_contact_ids_by_outer_group), do: []

  defp count_unique_contact_ids(contact_ids) do
    contact_ids
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
