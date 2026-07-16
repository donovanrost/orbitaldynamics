defmodule OrbitalDynamics.Schema.CandidateRefreshCommunicationPressureContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      validate_non_negative_integer_count_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_stable_id_list: 3
    ]

  def validate_contact_contention(issues, path, summary) do
    validate_count_maps(issues, path, summary, [
      "contact_contention_ground_station_counts",
      "contact_contention_contact_id_counts"
    ])
  end

  def validate_contact_allocation(issues, path, summary) do
    Enum.reduce(
      [
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station",
        "provider_reservation_request_contact_ids_by_direction_and_ground_station",
        "provider_reservation_review_contact_ids_by_direction_and_ground_station"
      ],
      issues,
      fn field, acc ->
        validate_nested_stable_id_array_map(acc, path <> ".#{field}", Map.get(summary, field))
      end
    )
  end

  def validate_station_pressure(issues, path, summary) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "station_pressure_contact_count"
    )
    |> validate_count_maps(path, summary, [
      "station_pressure_ground_station_counts",
      "station_pressure_availability_counts",
      "station_pressure_precedence_availability_counts",
      "station_pressure_precedence_rank_counts"
    ])
  end

  def validate_contact_filter(issues, path, summary) do
    issues
    |> validate_stable_id_list(
      path <> ".invalid_contact_input_ids",
      Map.get(summary, "invalid_contact_input_ids")
    )
    |> expect_optional_non_negative_integer(path, summary, "station_suppression_count")
    |> validate_count_maps(path, summary, [
      "station_suppression_ground_station_counts",
      "station_suppression_availability_counts",
      "station_suppression_status_counts"
    ])
  end

  defp validate_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_non_negative_integer_count_map(acc, path <> ".#{field}", Map.get(summary, field))
    end)
  end
end
