defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffFieldValues do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ScalarValues, ValueEncoding}

  def match_status(planned, realized)
      when planned in [nil, ""] and realized in [nil, ""],
      do: nil

  def match_status(planned, _realized) when planned in [nil, ""],
    do: "realized_only"

  def match_status(_planned, realized) when realized in [nil, ""],
    do: "planned_only"

  def match_status(value, value), do: "matched"
  def match_status(_planned, _realized), do: "mismatch"

  def first_boolean(row, fields), do: first_boolean(row, fields, default_callbacks())

  def first_boolean(row, fields, callbacks) do
    fields
    |> Enum.map(&field_value(row, &1))
    |> Enum.map(&callback!(callbacks, :json_boolean_value).(&1))
    |> Enum.find(&is_boolean/1)
  end

  def first_number(row, fields), do: first_number(row, fields, default_callbacks())

  def first_number(row, fields, callbacks) do
    fields
    |> Enum.map(&field_value(row, &1))
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  def first_string(row, fields), do: first_string(row, fields, default_callbacks())

  def first_string(row, fields, callbacks) do
    fields
    |> Enum.map(&field_value(row, &1))
    |> Enum.map(&callback!(callbacks, :encode_value).(&1))
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  def first_stable_id(row, fields), do: first_stable_id(row, fields, default_callbacks())

  def first_stable_id(row, fields, callbacks) do
    fields
    |> Enum.map(&field_value(row, &1))
    |> Enum.map(&callback!(callbacks, :encode_value).(&1))
    |> Enum.find(&callback!(callbacks, :stable_id_string?).(&1))
  end

  def field_value(row, path) when is_list(path), do: get_in(row, path)
  def field_value(row, field), do: row[field]

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      encode_value: &ValueEncoding.encode_value/1,
      json_boolean_value: &ScalarValues.json_boolean_value/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1
    ]
  end
end
