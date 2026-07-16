defmodule OrbitalDynamics.Schema.StationCalendarContactCountContracts do
  @moduledoc false

  @count_list_pairs [
    {"station_calendar_overlap_count", "station_calendar_overlap_entry_ids"},
    {"station_calendar_ambiguous_entry_count", "station_calendar_ambiguous_entry_ids"},
    {"station_calendar_reservation_overlap_count", "station_calendar_reservation_ids"}
  ]

  def validate(issues, path, contact, callbacks) when is_list(callbacks) do
    Enum.reduce(@count_list_pairs, issues, fn {count_field, list_field}, acc ->
      expect_field_equals(
        acc,
        callbacks,
        path,
        contact,
        count_field,
        list_count(callbacks, contact, list_field)
      )
    end)
  end

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp list_count(callbacks, map, field),
    do: apply(require_callback(callbacks, :list_count), [map, field])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
