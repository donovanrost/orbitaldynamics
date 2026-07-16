defmodule OrbitalDynamics.Schema.CandidateRefreshContactIntentRoutingContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CollectionAggregation

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_optional_field_equals: 6,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      validate_non_negative_number_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_array_map: 3, validate_stable_id_list: 3]

  def validate(issues, _path, value, _summary) when value in [nil, :null], do: issues

  def validate(issues, path, %{} = routing, summary) do
    Enum.reduce(routing, issues, fn {direction, route}, acc ->
      route_path = "#{path}.direction_routing.#{direction}"

      case route do
        %{} = route ->
          acc
          |> expect_optional_non_negative_integer(route_path, route, "contact_count")
          |> validate_stable_id_list(
            route_path <> ".contact_ids",
            Map.get(route, "contact_ids")
          )
          |> expect_optional_number(
            route_path,
            route,
            "capacity_pack_required_capacity_fraction"
          )
          |> validate_non_negative_number_map(
            route_path,
            CollectionAggregation.single_field_map(
              route,
              "capacity_pack_required_capacity_fraction"
            )
          )
          |> validate_route_stable_ids(route_path, route)
          |> validate_route_fraction_maps(route_path, route)
          |> validate_direction_route_consistency(route_path, route, direction, summary)

        _route ->
          [error(route_path, "must be an object") | acc]
      end
    end)
  end

  def validate(issues, path, _value, _summary),
    do: [error(path <> ".direction_routing", "must be an object") | issues]

  defp validate_route_stable_ids(issues, route_path, route) do
    issues =
      Enum.reduce(
        ["capacity_pack_contact_ids", "ground_station_ids"],
        issues,
        fn field, acc ->
          validate_stable_id_list(acc, route_path <> ".#{field}", Map.get(route, field))
        end
      )

    Enum.reduce(
      [
        "contact_ids_by_ground_station",
        "contact_ids_by_ground_station_id",
        "capacity_pack_contact_ids_by_ground_station",
        "capacity_pack_contact_ids_by_ground_station_id"
      ],
      issues,
      fn field, acc ->
        validate_stable_id_array_map(acc, route_path <> ".#{field}", Map.get(route, field))
      end
    )
  end

  defp validate_route_fraction_maps(issues, route_path, route) do
    Enum.reduce(
      [
        "capacity_pack_required_capacity_fraction_by_ground_station",
        "capacity_pack_required_capacity_fraction_by_ground_station_id"
      ],
      issues,
      fn field, acc ->
        validate_non_negative_number_map(acc, route_path <> ".#{field}", Map.get(route, field))
      end
    )
  end

  defp validate_direction_route_consistency(issues, path, route, direction, summary) do
    contact_ids_by_station =
      direction_route_nested_map(summary, direction, [
        "contact_ids_by_direction_and_ground_station",
        "contact_ids_by_direction_and_ground_station_id"
      ])

    capacity_contact_ids_by_station =
      direction_route_nested_map(summary, direction, [
        "capacity_pack_contact_ids_by_direction_and_ground_station",
        "capacity_pack_contact_ids_by_direction_and_ground_station_id"
      ])

    required_by_station =
      direction_route_nested_map(summary, direction, [
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station",
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id"
      ])

    station_ids =
      case contact_ids_by_station do
        %{} -> contact_ids_by_station |> Map.keys() |> Enum.sort()
        _value -> nil
      end

    issues
    |> expect_optional_field_equals(
      path,
      route,
      "ground_station_ids",
      station_ids,
      "must equal contact_ids_by_direction_and_ground_station keys"
    )
    |> expect_optional_field_equals(
      path,
      route,
      "contact_ids_by_ground_station",
      contact_ids_by_station,
      "must equal contact_ids_by_direction_and_ground_station for this direction"
    )
    |> expect_optional_field_equals(
      path,
      route,
      "contact_ids_by_ground_station_id",
      contact_ids_by_station,
      "must equal contact_ids_by_direction_and_ground_station_id for this direction"
    )
    |> expect_optional_field_equals(
      path,
      route,
      "capacity_pack_contact_ids_by_ground_station",
      capacity_contact_ids_by_station,
      "must equal capacity_pack_contact_ids_by_direction_and_ground_station for this direction"
    )
    |> expect_optional_field_equals(
      path,
      route,
      "capacity_pack_contact_ids_by_ground_station_id",
      capacity_contact_ids_by_station,
      "must equal capacity_pack_contact_ids_by_direction_and_ground_station_id for this direction"
    )
    |> expect_optional_field_equals(
      path,
      route,
      "capacity_pack_required_capacity_fraction_by_ground_station",
      required_by_station,
      "must equal capacity_pack_required_capacity_fraction_by_direction_and_ground_station for this direction"
    )
    |> expect_optional_field_equals(
      path,
      route,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      required_by_station,
      "must equal capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id for this direction"
    )
  end

  defp direction_route_nested_map(summary, direction, fields) do
    Enum.find_value(fields, fn field ->
      case get_in(summary, [field, direction]) do
        %{} = values -> values
        _value -> nil
      end
    end)
  end
end
