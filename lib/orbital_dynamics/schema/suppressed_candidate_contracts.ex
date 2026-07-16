defmodule OrbitalDynamics.Schema.SuppressedCandidateContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_field_at_least: 5,
      expect_field_at_most: 5,
      expect_field_equals: 6,
      expect_optional_integer: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

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

  def validate(issues, path, candidate) do
    issues
    |> require_fields(path, candidate, [
      "id",
      "type",
      "scenario_id",
      "suppressed_reason"
    ])
    |> validate_stable_ids(path, candidate, @stable_id_fields)
    |> expect_optional_number(path, candidate, "starts_at_s")
    |> expect_optional_number(path, candidate, "ends_at_s")
    |> expect_optional_number(path, candidate, "capacity_fraction")
    |> expect_field_at_least(path, candidate, "capacity_fraction", 0.0)
    |> expect_field_at_most(path, candidate, "capacity_fraction", 1.0)
    |> expect_optional_type(path, candidate, "station_calendar_status", :binary)
    |> expect_optional_integer(path, candidate, "station_calendar_precedence_rank")
    |> expect_field_at_least(path, candidate, "station_calendar_precedence_rank", 0)
    |> expect_optional_type(
      path,
      candidate,
      "station_calendar_precedence_availability",
      :binary
    )
    |> expect_optional_type(path, candidate, "station_availability", :binary)
    |> expect_optional_type(path, candidate, "station_contention_status", :binary)
    |> expect_optional_type(path, candidate, "station_reserved_by", :binary)
    |> expect_optional_type(path, candidate, "station_reservation_status", :binary)
    |> expect_optional_type(
      path,
      candidate,
      "station_reservation_match_status",
      :binary
    )
    |> expect_optional_type(path, candidate, "resource_blocking_dimension", :binary)
    |> expect_optional_type(path, candidate, "resource_trust_boundary_status", :binary)
    |> expect_optional_type(path, candidate, "incompatible_activity_types", :list)
    |> validate_string_list_items(path, candidate, "incompatible_activity_types")
    |> expect_optional_type(path, candidate, "suppressed_activity_types", :list)
    |> validate_string_list_items(path, candidate, "suppressed_activity_types")
    |> expect_optional_one_of(path, candidate, "review_status", @review_statuses)
    |> validate_station_calendar_overlap_counts(path, candidate)
    |> validate_duplicate_evidence(path, candidate)
  end

  def validate_duplicate_evidence(issues, path, candidate) do
    if Map.get(candidate, "duplicate_suppressed_candidate_id_collision") == true and
         not Map.has_key?(candidate, "base_candidate_id") do
      [error(path <> ".base_candidate_id", "is required") | issues]
    else
      issues
    end
  end

  defp validate_station_calendar_overlap_counts(issues, path, candidate) do
    issues
    |> expect_field_at_least(
      path,
      candidate,
      "station_calendar_overlap_count",
      list_count(candidate, "station_calendar_overlap_entry_ids")
    )
    |> expect_field_equals(
      path,
      candidate,
      "station_calendar_ambiguous_entry_count",
      list_count(candidate, "station_calendar_ambiguous_entry_ids")
    )
    |> expect_field_at_least(
      path,
      candidate,
      "station_calendar_reservation_overlap_count",
      list_count(candidate, "station_calendar_reservation_overlap_entry_ids")
    )
  end

  defp expect_field_equals(issues, path, candidate, field, expected),
    do: expect_field_equals(issues, path, candidate, field, expected, "must equal #{expected}")

  defp list_count(map, field) do
    OrbitalDynamics.Schema.CollectionAggregation.list_count(map, field)
  end
end
