defmodule OrbitalDynamics.Schema.CandidateRefreshContactIntentContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CandidateRefreshContactIntentRoutingContracts

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      validate_nested_non_negative_number_map: 3,
      validate_non_negative_integer_count_map: 3,
      validate_non_negative_number_map: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_stable_id_array_map: 3
    ]

  def validate(issues, path, summary) do
    issues
    |> expect_optional_non_negative_integer(path, summary, "station_feedback_count")
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "capacity_pack_required_contact_count"
    )
    |> expect_optional_number(
      path,
      summary,
      "capacity_pack_required_capacity_fraction"
    )
    |> validate_count_maps(path, summary, [
      "station_calendar_status_counts",
      "cadence_import_status_counts",
      "policy_classification_counts",
      "required_capacity_fraction_source_counts",
      "direction_counts"
    ])
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_required_capacity_fraction_by_ground_station",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_ground_station")
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_required_capacity_fraction_by_direction",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_direction")
    )
    |> validate_nested_non_negative_number_map(
      path <> ".capacity_pack_required_capacity_fraction_by_direction_and_ground_station",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_direction_and_ground_station")
    )
    |> validate_stable_id_maps(path, summary)
    |> validate_string_list_items(path, summary, "directions")
    |> CandidateRefreshContactIntentRoutingContracts.validate(
      path,
      Map.get(summary, "direction_routing"),
      summary
    )
  end

  defp validate_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_non_negative_integer_count_map(acc, path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp validate_stable_id_maps(issues, path, summary) do
    issues =
      Enum.reduce(
        [
          "required_capacity_fraction_contact_ids_by_source",
          "capacity_pack_contact_ids_by_ground_station",
          "contact_ids_by_ground_station",
          "capacity_pack_contact_ids_by_direction",
          "contact_ids_by_direction"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_array_map(acc, path <> ".#{field}", Map.get(summary, field))
        end
      )

    Enum.reduce(
      [
        "capacity_pack_contact_ids_by_direction_and_ground_station",
        "contact_ids_by_direction_and_ground_station"
      ],
      issues,
      fn field, acc ->
        validate_nested_stable_id_array_map(acc, path <> ".#{field}", Map.get(summary, field))
      end
    )
  end
end
