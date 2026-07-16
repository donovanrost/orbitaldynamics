defmodule OrbitalDynamics.Schema.PriorityOverrideContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation
  alias OrbitalDynamics.Schema.StableIdValidation

  def validate_map(issues, path, overrides) when is_map(overrides) do
    Enum.reduce(overrides, issues, fn {contact_id, priority}, acc ->
      acc
      |> StableIdValidation.validate_stable_id("#{path}.#{contact_id}", contact_id)
      |> validate_value("#{path}.#{contact_id}", priority)
    end)
  end

  def validate_map(issues, _path, _overrides), do: issues

  def validate_count_matches_ids(issues, path, map, count_field, ids_field) when is_map(map) do
    case {Map.get(map, count_field), Map.get(map, ids_field)} do
      {count, ids} when is_integer(count) and is_list(ids) and count != length(ids) ->
        [
          PrimitiveValidation.error(
            "#{path}.#{count_field}",
            "must equal length of #{ids_field}"
          )
          | issues
        ]

      _value ->
        issues
    end
  end

  def validate_ids_match_map(issues, path, policy) when is_map(policy) do
    overrides = Map.get(policy, "priority_overrides")
    contact_ids = Map.get(policy, "priority_override_contact_ids")
    count = Map.get(policy, "priority_override_count")

    issues
    |> validate_count_matches_map(path, count, overrides)
    |> validate_ids_match_map(path, contact_ids, overrides)
  end

  defp validate_value(issues, _path, value) when is_number(value), do: issues

  defp validate_value(issues, path, _value),
    do: [PrimitiveValidation.error(path, "must be a number") | issues]

  defp validate_count_matches_map(issues, path, count, overrides)
       when is_integer(count) and is_map(overrides) and count != map_size(overrides) do
    [
      PrimitiveValidation.error(
        "#{path}.priority_override_count",
        "must equal size of priority_overrides"
      )
      | issues
    ]
  end

  defp validate_count_matches_map(issues, _path, _count, _overrides), do: issues

  defp validate_ids_match_map(issues, path, contact_ids, overrides)
       when is_list(contact_ids) and is_map(overrides) do
    expected = overrides |> Map.keys() |> Enum.sort()
    actual = Enum.sort(contact_ids)

    if expected == actual do
      issues
    else
      [
        PrimitiveValidation.error(
          "#{path}.priority_override_contact_ids",
          "must match priority_overrides keys"
        )
        | issues
      ]
    end
  end

  defp validate_ids_match_map(issues, _path, _contact_ids, _overrides), do: issues
end
