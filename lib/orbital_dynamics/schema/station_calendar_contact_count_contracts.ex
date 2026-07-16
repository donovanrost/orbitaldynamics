defmodule OrbitalDynamics.Schema.StationCalendarContactCountContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation, only: [list_count: 2]
  import OrbitalDynamics.Schema.PrimitiveValidation, only: [expect_field_equals: 5]

  @count_list_pairs [
    {"station_calendar_overlap_count", "station_calendar_overlap_entry_ids"},
    {"station_calendar_ambiguous_entry_count", "station_calendar_ambiguous_entry_ids"},
    {"station_calendar_reservation_overlap_count", "station_calendar_reservation_ids"}
  ]

  def validate(issues, path, contact) do
    Enum.reduce(@count_list_pairs, issues, fn {count_field, list_field}, acc ->
      expect_field_equals(
        acc,
        path,
        contact,
        count_field,
        list_count(contact, list_field)
      )
    end)
  end
end
