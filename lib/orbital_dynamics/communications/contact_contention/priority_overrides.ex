defmodule OrbitalDynamics.Communications.ContactContention.PriorityOverrides do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactContention.ContactNormalization

  @aliases ~w(
    priority_overrides
    contact_priority_overrides
    contact_priorities
    priority_by_contact_id
  )
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def aliases, do: @aliases

  def normalize(policy) do
    {priority_overrides, ignored_override_context} =
      policy
      |> raw()
      |> normalized()

    policy =
      if map_size(priority_overrides) == 0 do
        policy
      else
        Map.put(policy, "priority_overrides", priority_overrides)
      end

    Map.merge(policy, ignored_override_context)
  end

  def count(policy), do: map_size(Map.get(policy, "priority_overrides", %{}))

  def ignored_count(policy), do: Map.get(policy, "ignored_priority_override_count", 0)

  def values(policy) do
    case Map.get(policy, "priority_overrides", %{}) do
      overrides when map_size(overrides) == 0 -> nil
      overrides -> overrides
    end
  end

  def contact_ids(policy) do
    policy
    |> Map.get("priority_overrides", %{})
    |> Map.keys()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def ignored_keys(policy), do: Map.get(policy, "ignored_priority_override_keys")

  def ignored_contact_ids(policy),
    do: Map.get(policy, "ignored_priority_override_contact_ids")

  defp raw(policy) do
    Enum.find_value(@aliases, &Map.get(policy, &1)) || %{}
  end

  defp normalized(%{} = overrides) do
    {priority_overrides, ignored_keys, ignored_contact_ids} =
      Enum.reduce(overrides, {%{}, [], []}, fn {raw_id, raw_priority},
                                               {priority_overrides, ignored_keys,
                                                ignored_contact_ids} ->
        contact_id = stable_id_or_nil(raw_id)
        priority = ContactNormalization.numeric_or_nil(raw_priority)

        if is_binary(contact_id) and is_number(priority) do
          {Map.put(priority_overrides, contact_id, priority), ignored_keys, ignored_contact_ids}
        else
          ignored_key = ContactNormalization.encode_value(raw_id) || inspect(raw_id, limit: 20)

          ignored_contact_ids =
            if is_binary(contact_id),
              do: [contact_id | ignored_contact_ids],
              else: ignored_contact_ids

          {priority_overrides, [ignored_key | ignored_keys], ignored_contact_ids}
        end
      end)

    ignored_context =
      ignored_context(ignored_keys, ignored_contact_ids, nil)

    {priority_overrides, ignored_context}
  end

  defp normalized(overrides) do
    {%{}, ignored_context([], [], inspect(overrides, limit: 20))}
  end

  defp ignored_context(ignored_keys, ignored_contact_ids, ignored_input) do
    ignored_keys =
      ignored_keys
      |> Enum.map(&ContactNormalization.encode_value/1)
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()

    ignored_contact_ids =
      ignored_contact_ids
      |> Enum.uniq()
      |> Enum.sort()

    ignored_count = length(ignored_keys) + if(is_nil(ignored_input), do: 0, else: 1)

    %{
      "ignored_priority_override_count" => if(ignored_count == 0, do: nil, else: ignored_count),
      "ignored_priority_override_keys" => if(ignored_keys == [], do: nil, else: ignored_keys),
      "ignored_priority_override_contact_ids" =>
        if(ignored_contact_ids == [], do: nil, else: ignored_contact_ids),
      "ignored_priority_override_input" => ignored_input
    }
    |> ContactNormalization.compact_map()
  end

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil("nil"), do: nil

  defp stable_id_or_nil(value) when is_binary(value) do
    if Regex.match?(@stable_id_pattern, value), do: value
  end

  defp stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(_value), do: nil
end
