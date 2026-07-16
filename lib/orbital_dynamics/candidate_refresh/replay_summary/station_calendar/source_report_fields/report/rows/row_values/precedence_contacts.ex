defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.RowValues.PrecedenceContacts do
  @moduledoc false

  @contact_ids_by_key_fields [
    "affected_contact_ids_by_applied_availability",
    "affected_contact_ids_by_overlap_availability",
    "reserved_under_higher_precedence_contact_ids_by_applied_availability",
    "reserved_under_higher_precedence_contact_ids_by_reservation_status",
    "reserved_under_higher_precedence_contact_ids_by_reserved_by"
  ]

  @contact_id_list_fields [
    "reserved_under_higher_precedence_contact_ids",
    "unavailable_contact_ids",
    "reserved_overlap_contact_ids",
    "reduced_capacity_contact_ids"
  ]

  def precedence_contact_ids(report) do
    report
    |> contact_ids_by_key_values()
    |> Kernel.++(contact_id_list_values(report))
  end

  defp contact_ids_by_key_values(report) do
    @contact_ids_by_key_fields
    |> Enum.map(&Map.get(report, &1, %{}))
    |> Enum.flat_map(fn
      %{} = contact_ids_by_key -> Map.values(contact_ids_by_key)
      _contact_ids_by_key -> []
    end)
    |> List.flatten()
  end

  defp contact_id_list_values(report) do
    @contact_id_list_fields
    |> Enum.flat_map(&List.wrap(Map.get(report, &1, [])))
  end
end
