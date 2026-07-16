defmodule OrbitalDynamics.Schema.PriorityOverrideContracts do
  @moduledoc false

  def validate_map(issues, path, overrides, callbacks)
      when is_map(overrides) and is_list(callbacks) do
    Enum.reduce(overrides, issues, fn {contact_id, priority}, acc ->
      acc
      |> validate_stable_id(callbacks, "#{path}.#{contact_id}", contact_id)
      |> validate_value(callbacks, "#{path}.#{contact_id}", priority)
    end)
  end

  def validate_map(issues, _path, _overrides, callbacks) when is_list(callbacks), do: issues

  def validate_count_matches_ids(issues, path, map, count_field, ids_field, callbacks)
      when is_map(map) and is_list(callbacks) do
    case {Map.get(map, count_field), Map.get(map, ids_field)} do
      {count, ids} when is_integer(count) and is_list(ids) and count != length(ids) ->
        [error(callbacks, "#{path}.#{count_field}", "must equal length of #{ids_field}") | issues]

      _value ->
        issues
    end
  end

  def validate_ids_match_map(issues, path, policy, callbacks)
      when is_map(policy) and is_list(callbacks) do
    overrides = Map.get(policy, "priority_overrides")
    contact_ids = Map.get(policy, "priority_override_contact_ids")
    count = Map.get(policy, "priority_override_count")

    issues
    |> validate_count_matches_map(path, count, overrides, callbacks)
    |> validate_ids_match_map(path, contact_ids, overrides, callbacks)
  end

  defp validate_value(issues, _callbacks, _path, value) when is_number(value), do: issues

  defp validate_value(issues, callbacks, path, _value),
    do: [error(callbacks, path, "must be a number") | issues]

  defp validate_count_matches_map(issues, path, count, overrides, callbacks)
       when is_integer(count) and is_map(overrides) and count != map_size(overrides) do
    [
      error(callbacks, "#{path}.priority_override_count", "must equal size of priority_overrides")
      | issues
    ]
  end

  defp validate_count_matches_map(issues, _path, _count, _overrides, _callbacks),
    do: issues

  defp validate_ids_match_map(issues, path, contact_ids, overrides, callbacks)
       when is_list(contact_ids) and is_map(overrides) do
    expected = overrides |> Map.keys() |> Enum.sort()
    actual = Enum.sort(contact_ids)

    if expected == actual do
      issues
    else
      [
        error(
          callbacks,
          "#{path}.priority_override_contact_ids",
          "must match priority_overrides keys"
        )
        | issues
      ]
    end
  end

  defp validate_ids_match_map(issues, _path, _contact_ids, _overrides, _callbacks),
    do: issues

  defp validate_stable_id(issues, callbacks, path, value),
    do: apply(require_callback(callbacks, :validate_stable_id), [issues, path, value])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
