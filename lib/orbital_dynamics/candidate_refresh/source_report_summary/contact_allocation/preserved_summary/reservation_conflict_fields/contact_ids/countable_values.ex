defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ReservationConflictFields.ContactIds.CountableValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ReservationConflictFields.ContactIds.FieldGroups

  def values(summary) do
    contact_id_lists = present_values(summary, FieldGroups.list_fields())
    flat_contact_id_maps = present_values(summary, FieldGroups.flat_fields())
    nested_contact_id_maps = present_values(summary, FieldGroups.nested_fields())

    if contact_id_lists != [] or flat_contact_id_maps != [] or nested_contact_id_maps != [] do
      contact_id_lists
      |> Enum.flat_map(&list_value/1)
      |> Kernel.++(flat_contact_ids(flat_contact_id_maps))
      |> Kernel.++(nested_contact_ids(nested_contact_id_maps))
    end
  end

  defp present_values(summary, fields) do
    fields
    |> Enum.filter(&Map.has_key?(summary, &1))
    |> Enum.map(&Map.get(summary, &1))
  end

  defp flat_contact_ids(flat_contact_id_maps) do
    flat_contact_id_maps
    |> Enum.flat_map(&ContactIntent.string_list_map_contact_ids/1)
  end

  defp nested_contact_ids(nested_contact_id_maps) do
    nested_contact_id_maps
    |> Enum.flat_map(&ContactIntent.nested_string_list_map_contact_ids/1)
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
