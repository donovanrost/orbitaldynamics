defmodule OrbitalDynamics.Schema.SuppressedCandidateContracts do
  @moduledoc false

  @stable_id_fields [
    "id",
    "scenario_id",
    "source_window_id",
    "ground_station_id",
    "station_calendar_entry_id",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id",
    "station_reservation_id"
  ]

  @review_statuses [
    "operator_review_required",
    "review_required",
    "pending_operator_review",
    "ready_for_review"
  ]

  def validate(issues, path, candidate, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, candidate, [
      "id",
      "type",
      "scenario_id",
      "suppressed_reason"
    ])
    |> validate_stable_ids(callbacks, path, candidate, @stable_id_fields)
    |> expect_optional_number(callbacks, path, candidate, "starts_at_s")
    |> expect_optional_number(callbacks, path, candidate, "ends_at_s")
    |> expect_optional_number(callbacks, path, candidate, "capacity_fraction")
    |> expect_field_at_least(callbacks, path, candidate, "capacity_fraction", 0.0)
    |> expect_field_at_most(callbacks, path, candidate, "capacity_fraction", 1.0)
    |> expect_optional_type(callbacks, path, candidate, "station_calendar_status", :binary)
    |> expect_optional_integer(callbacks, path, candidate, "station_calendar_precedence_rank")
    |> expect_field_at_least(callbacks, path, candidate, "station_calendar_precedence_rank", 0)
    |> expect_optional_type(
      callbacks,
      path,
      candidate,
      "station_calendar_precedence_availability",
      :binary
    )
    |> expect_optional_type(callbacks, path, candidate, "station_availability", :binary)
    |> expect_optional_type(callbacks, path, candidate, "station_contention_status", :binary)
    |> expect_optional_type(callbacks, path, candidate, "station_reserved_by", :binary)
    |> expect_optional_type(callbacks, path, candidate, "station_reservation_status", :binary)
    |> expect_optional_type(
      callbacks,
      path,
      candidate,
      "station_reservation_match_status",
      :binary
    )
    |> expect_optional_type(callbacks, path, candidate, "resource_blocking_dimension", :binary)
    |> expect_optional_type(callbacks, path, candidate, "resource_trust_boundary_status", :binary)
    |> expect_optional_type(callbacks, path, candidate, "incompatible_activity_types", :list)
    |> validate_string_list_items(callbacks, path, candidate, "incompatible_activity_types")
    |> expect_optional_type(callbacks, path, candidate, "suppressed_activity_types", :list)
    |> validate_string_list_items(callbacks, path, candidate, "suppressed_activity_types")
    |> expect_optional_one_of(callbacks, path, candidate, "review_status", @review_statuses)
    |> validate_station_calendar_overlap_counts(callbacks, path, candidate)
    |> validate_duplicate_evidence(path, candidate, callbacks)
  end

  def validate_duplicate_evidence(issues, path, candidate, callbacks) when is_list(callbacks) do
    if Map.get(candidate, "duplicate_suppressed_candidate_id_collision") == true and
         not Map.has_key?(candidate, "base_candidate_id") do
      [error(callbacks, path <> ".base_candidate_id", "is required") | issues]
    else
      issues
    end
  end

  defp validate_station_calendar_overlap_counts(issues, callbacks, path, candidate) do
    issues
    |> expect_field_at_least(
      callbacks,
      path,
      candidate,
      "station_calendar_overlap_count",
      list_count(candidate, "station_calendar_overlap_entry_ids")
    )
    |> expect_field_equals(
      callbacks,
      path,
      candidate,
      "station_calendar_ambiguous_entry_count",
      list_count(candidate, "station_calendar_ambiguous_entry_ids")
    )
    |> expect_field_at_least(
      callbacks,
      path,
      candidate,
      "station_calendar_reservation_overlap_count",
      list_count(candidate, "station_calendar_reservation_overlap_entry_ids")
    )
  end

  defp list_count(map, field) do
    OrbitalDynamics.Schema.CollectionAggregation.list_count(map, field)
  end

  defp error(callbacks, path, message), do: callback!(callbacks, :error).(path, message)

  defp expect_field_at_least(issues, callbacks, path, candidate, field, minimum) do
    callback!(callbacks, :expect_field_at_least).(issues, path, candidate, field, minimum)
  end

  defp expect_field_at_most(issues, callbacks, path, candidate, field, maximum) do
    callback!(callbacks, :expect_field_at_most).(issues, path, candidate, field, maximum)
  end

  defp expect_field_equals(issues, callbacks, path, candidate, field, expected) do
    callback!(callbacks, :expect_field_equals).(issues, path, candidate, field, expected)
  end

  defp expect_optional_integer(issues, callbacks, path, candidate, field) do
    callback!(callbacks, :expect_optional_integer).(issues, path, candidate, field)
  end

  defp expect_optional_number(issues, callbacks, path, candidate, field) do
    callback!(callbacks, :expect_optional_number).(issues, path, candidate, field)
  end

  defp expect_optional_one_of(issues, callbacks, path, candidate, field, values) do
    callback!(callbacks, :expect_optional_one_of).(issues, path, candidate, field, values)
  end

  defp expect_optional_type(issues, callbacks, path, candidate, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, candidate, field, type)
  end

  defp require_fields(issues, callbacks, path, candidate, fields) do
    callback!(callbacks, :require_fields).(issues, path, candidate, fields)
  end

  defp validate_stable_ids(issues, callbacks, path, candidate, fields) do
    callback!(callbacks, :validate_stable_ids).(issues, path, candidate, fields)
  end

  defp validate_string_list_items(issues, callbacks, path, candidate, field) do
    callback!(callbacks, :validate_string_list_items).(issues, path, candidate, field)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
