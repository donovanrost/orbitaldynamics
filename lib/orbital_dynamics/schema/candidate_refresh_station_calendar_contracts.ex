defmodule OrbitalDynamics.Schema.CandidateRefreshStationCalendarContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CollectionAggregation

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      validate_non_negative_integer_count_map: 3,
      validate_non_negative_number_list: 3,
      validate_non_negative_number_map: 3,
      validate_number_array_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_array_map: 3, validate_stable_id_list: 3]

  def validate(issues, path, summary) do
    issues
    |> expect_optional_non_negative_integer(path, summary, "affected_contact_count")
    |> validate_stable_id_lists(path, summary)
    |> validate_count_maps(path, summary, [
      "affected_contact_ground_station_counts",
      "affected_contact_availability_counts",
      "direction_counts"
    ])
    |> validate_direction_maps(path, summary)
    |> validate_direction_routing(path, Map.get(summary, "direction_routing"))
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "provider_calendar_contention_group_count"
    )
    |> validate_provider_contention(path, summary)
  end

  defp validate_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_non_negative_integer_count_map(acc, path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp validate_stable_id_lists(issues, path, summary) do
    Enum.reduce(
      [
        "affected_contact_ids",
        "affected_station_calendar_entry_ids",
        "affected_station_reservation_ids"
      ],
      issues,
      fn field, acc ->
        validate_stable_id_list(acc, path <> ".#{field}", Map.get(summary, field))
      end
    )
  end

  defp validate_direction_maps(issues, path, summary) do
    issues =
      Enum.reduce(
        [
          "contact_ids_by_direction",
          "station_calendar_entry_ids_by_direction",
          "station_reservation_ids_by_direction"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_array_map(acc, path <> ".#{field}", Map.get(summary, field))
        end
      )

    validate_number_array_map(
      issues,
      path <> ".station_capacity_fractions_by_direction",
      Map.get(summary, "station_capacity_fractions_by_direction")
    )
  end

  defp validate_direction_routing(issues, _path, value) when value in [nil, :null], do: issues

  defp validate_direction_routing(issues, path, %{} = routing) do
    Enum.reduce(routing, issues, fn {direction, route}, acc ->
      route_path = "#{path}.direction_routing.#{direction}"

      case route do
        %{} = route ->
          acc
          |> expect_optional_non_negative_integer(route_path, route, "contact_count")
          |> validate_direction_route(route_path, route)

        _route ->
          [error(route_path, "must be an object") | acc]
      end
    end)
  end

  defp validate_direction_routing(issues, path, _value),
    do: [error(path <> ".direction_routing", "must be an object") | issues]

  defp validate_direction_route(issues, route_path, route) do
    issues =
      Enum.reduce(
        [
          "contact_ids",
          "station_calendar_entry_ids",
          "station_reservation_ids",
          "provider_contention_group_ids",
          "provider_contention_source_entry_ids",
          "provider_contention_provider_entry_ids"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_list(acc, route_path <> ".#{field}", Map.get(route, field))
        end
      )

    issues
    |> validate_non_negative_number_list(
      route_path <> ".station_capacity_fractions",
      Map.get(route, "station_capacity_fractions")
    )
    |> expect_optional_non_negative_integer(
      route_path,
      route,
      "provider_contention_group_count"
    )
    |> validate_non_negative_number_list(
      route_path <> ".provider_contention_capacity_fractions",
      Map.get(route, "provider_contention_capacity_fractions")
    )
  end

  defp validate_provider_contention(issues, path, summary) do
    issues =
      Enum.reduce(
        [
          "provider_calendar_contention_group_ids",
          "provider_calendar_contention_source_entry_ids",
          "provider_calendar_contention_provider_entry_ids"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_list(acc, path <> ".#{field}", Map.get(summary, field))
        end
      )

    issues =
      issues
      |> validate_non_negative_number_list(
        path <> ".provider_calendar_contention_capacity_fractions",
        Map.get(summary, "provider_calendar_contention_capacity_fractions")
      )
      |> expect_optional_number(
        path,
        summary,
        "provider_calendar_contention_minimum_capacity_fraction"
      )
      |> validate_non_negative_number_map(
        path,
        CollectionAggregation.single_field_map(
          summary,
          "provider_calendar_contention_minimum_capacity_fraction"
        )
      )
      |> validate_count_maps(path, summary, [
        "provider_calendar_contention_provider_counts",
        "provider_calendar_contention_ground_station_counts",
        "provider_calendar_contention_direction_counts"
      ])

    issues =
      Enum.reduce(
        [
          "provider_calendar_contention_group_ids_by_direction",
          "provider_calendar_contention_source_entry_ids_by_direction",
          "provider_calendar_contention_provider_entry_ids_by_direction"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_array_map(acc, path <> ".#{field}", Map.get(summary, field))
        end
      )

    validate_number_array_map(
      issues,
      path <> ".provider_calendar_contention_capacity_fractions_by_direction",
      Map.get(summary, "provider_calendar_contention_capacity_fractions_by_direction")
    )
  end
end
