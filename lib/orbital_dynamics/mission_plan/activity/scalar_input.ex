defmodule OrbitalDynamics.MissionPlan.Activity.ScalarInput do
  @moduledoc false

  alias OrbitalDynamics.MissionPlan.Activity.ExecutionUncertaintyInput

  def optional_boolean!(nil), do: nil
  def optional_boolean!(value) when is_boolean(value), do: value
  def optional_boolean!(value) when value in ["true", "1", 1], do: true
  def optional_boolean!(value) when value in ["false", "0", 0], do: false
  def optional_boolean!(_value), do: raise(ArgumentError, "boolean field must be a boolean")

  def optional_boolean!(nil, _field), do: nil
  def optional_boolean!(value, _field) when is_boolean(value), do: value
  def optional_boolean!(value, _field) when value in ["true", "1", 1], do: true
  def optional_boolean!(value, _field) when value in ["false", "0", 0], do: false
  def optional_boolean!(_value, field), do: raise(ArgumentError, "#{field} must be a boolean")

  def optional_boolean?(nil), do: true
  def optional_boolean?(value), do: is_boolean(value)

  def optional_number?(nil), do: true
  def optional_number?(value), do: is_number(value)

  def optional_non_negative_number?(nil), do: true

  def optional_non_negative_number?(value) when is_number(value),
    do: value >= 0.0

  def optional_non_negative_number?(_value), do: false

  def optional_non_negative_integer?(nil), do: true

  def optional_non_negative_integer?(value) when is_integer(value),
    do: value >= 0

  def optional_non_negative_integer?(_value), do: false

  def optional_unit_interval?(nil), do: true

  def optional_unit_interval?(value) when is_number(value),
    do: value >= 0.0 and value <= 1.0

  def optional_unit_interval?(_value), do: false

  def optional_scalar?(nil), do: true
  def optional_scalar?(value) when is_binary(value), do: value != ""
  def optional_scalar?(value) when is_atom(value), do: true
  def optional_scalar?(_value), do: false

  def optional_number_or_scalar?(nil), do: true
  def optional_number_or_scalar?(value) when is_number(value), do: true
  def optional_number_or_scalar?(value), do: optional_scalar?(value)

  def optional_number!(nil), do: nil

  def optional_number!(value) do
    case numeric_or_nil(value) do
      nil -> raise ArgumentError, "number fields must be numbers"
      number -> number
    end
  end

  def optional_non_negative_number!(nil, _field), do: nil

  def optional_non_negative_number!(value, field) do
    case numeric_or_nil(value) do
      number when is_number(number) and number >= 0.0 ->
        number

      number when is_number(number) ->
        raise ArgumentError, "#{field} must be a non-negative number"

      nil ->
        raise ArgumentError, "#{field} must be a number"
    end
  end

  def optional_non_negative_integer!(nil, _field), do: nil

  def optional_non_negative_integer!(value, _field) when is_integer(value) and value >= 0,
    do: value

  def optional_non_negative_integer!(value, field) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} when integer >= 0 ->
        integer

      _other ->
        raise ArgumentError, "#{field} must be a non-negative integer"
    end
  end

  def optional_non_negative_integer!(_value, field),
    do: raise(ArgumentError, "#{field} must be a non-negative integer")

  def optional_unit_interval!(nil, _field), do: nil

  def optional_unit_interval!(value, field) do
    case numeric_or_nil(value) do
      number when is_number(number) and number >= 0.0 and number <= 1.0 ->
        number

      number when is_number(number) ->
        raise ArgumentError, "#{field} must be between 0.0 and 1.0"

      nil ->
        raise ArgumentError, "#{field} must be a number"
    end
  end

  def optional_scalar!(nil), do: nil
  def optional_scalar!(value) when is_binary(value) and value != "", do: value
  def optional_scalar!(value) when is_atom(value) and not is_nil(value), do: value

  def optional_scalar!(_value),
    do: raise(ArgumentError, "scalar fields must be strings or atoms")

  def optional_scalar!(nil, _field), do: nil
  def optional_scalar!(value, _field) when is_binary(value) and value != "", do: value
  def optional_scalar!(value, _field) when is_atom(value) and not is_nil(value), do: value

  def optional_scalar!(_value, field),
    do: raise(ArgumentError, "#{field} must be nil, a string, or an atom")

  def optional_number_or_scalar!(nil), do: nil
  def optional_number_or_scalar!(value) when is_number(value), do: value

  def optional_number_or_scalar!(value) when is_binary(value) do
    case numeric_or_nil(value) do
      nil -> optional_scalar!(value)
      number -> number
    end
  end

  def optional_number_or_scalar!(value), do: optional_scalar!(value)

  defp numeric_or_nil(value), do: ExecutionUncertaintyInput.numeric_or_nil(value)
end
