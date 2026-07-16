defmodule OrbitalDynamics.CampaignPlanner.ScalarValues do
  @moduledoc false

  @stable_id_regex ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def truthy?(value), do: json_boolean_value(value) == true

  def numeric!(value, _field) when is_integer(value) or is_float(value), do: value

  def numeric!(value, field) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> raise ArgumentError, "#{field} must be numeric"
    end
  end

  def numeric!(_value, field), do: raise(ArgumentError, "#{field} must be numeric")

  def numeric_or_nil(nil), do: nil
  def numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  def numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  def numeric_or_nil(_value), do: nil

  def numeric_or_zero(value) when is_integer(value) or is_float(value), do: value * 1.0
  def numeric_or_zero(_value), do: 0.0

  def positive_number?(value), do: is_number(value) and value > 0.0

  def ceil_count(value) when is_integer(value), do: max(value, 0)
  def ceil_count(value) when is_float(value), do: value |> Float.ceil() |> trunc() |> max(0)
  def ceil_count(_value), do: 0

  def json_boolean_value(value) when is_boolean(value), do: value

  def json_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  def json_boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  def json_boolean_value(_value), do: nil

  def normalized_optional_status(nil), do: nil
  def normalized_optional_status(value), do: normalized_status_token(value)

  def normalized_status_token(nil), do: nil

  def normalized_status_token(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> normalized_status_token()
  end

  def normalized_status_token(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  def normalized_status_token(status), do: status

  def non_empty_string?(value), do: is_binary(value) and value != ""

  def stable_id_string?(value),
    do: non_empty_string?(value) and Regex.match?(@stable_id_regex, value)
end
