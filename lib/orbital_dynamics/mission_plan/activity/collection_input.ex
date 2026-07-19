defmodule OrbitalDynamics.MissionPlan.Activity.CollectionInput do
  @moduledoc false

  alias OrbitalDynamics.MissionPlan.Activity.ExecutionUncertaintyInput

  def valid_scalar_list?(values) when is_list(values) do
    match?({:ok, _values}, scalar_list_values(values))
  end

  def valid_scalar_list?(_values), do: false

  def optional_scalar_list!(nil, _field, _description), do: nil

  def optional_scalar_list!(values, field, description),
    do: scalar_list_input!(values, field, description)

  def scalar_list_input!(values, field, description) do
    case scalar_list_values(values) do
      {:ok, values} -> values
      :error -> raise ArgumentError, "#{field} must be a list of #{description}"
    end
  end

  def optional_non_negative_number_list!(nil, _field), do: nil

  def optional_non_negative_number_list!(values, field),
    do: non_negative_number_list_input!(values, field)

  def non_negative_number_list_input!(values, field) do
    case non_negative_number_list_values(values) do
      {:ok, numbers} -> numbers
      :error -> raise ArgumentError, "#{field} must be a list of non-negative numbers"
    end
  end

  def optional_map_list!(nil, _field, _description), do: nil

  def optional_map_list!(values, field, description),
    do: map_list_input!(values, field, description)

  def map_list_input!(values, field, description) do
    case map_list_values(values) do
      {:ok, maps} -> maps
      :error -> raise ArgumentError, "#{field} must be a list of #{description}"
    end
  end

  def optional_map!(nil), do: nil
  def optional_map!(value) when is_map(value), do: value
  def optional_map!(_value), do: raise(ArgumentError, "map fields must be maps")

  def optional_map!(nil, _field), do: nil
  def optional_map!(value, _field) when is_map(value), do: value

  def optional_map!(_value, field),
    do: raise(ArgumentError, "#{field} must be nil or a map")

  defp scalar_list_values(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, scalars} ->
      case scalar_list_values(value) do
        {:ok, value_scalars} -> {:cont, {:ok, scalars ++ value_scalars}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp scalar_list_values(value) do
    case scalar_list_value(value) do
      [] -> :error
      values -> {:ok, values}
    end
  end

  defp scalar_list_value(value) when is_atom(value) and not is_nil(value),
    do: [value]

  defp scalar_list_value(value) when is_binary(value) do
    values =
      value
      |> String.split(",", trim: false)
      |> Enum.map(&String.trim/1)

    if Enum.all?(values, &(&1 != "")), do: values, else: []
  end

  defp scalar_list_value(_value), do: []

  defp non_negative_number_list_values(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, numbers} ->
      case non_negative_number_list_values(value) do
        {:ok, value_numbers} -> {:cont, {:ok, numbers ++ value_numbers}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp non_negative_number_list_values(value) when is_binary(value) do
    values =
      value
      |> String.split(",", trim: false)
      |> Enum.map(&String.trim/1)

    numbers = Enum.map(values, &numeric_or_nil/1)

    if values != [] and Enum.all?(numbers, &(is_number(&1) and &1 >= 0.0)) do
      {:ok, numbers}
    else
      :error
    end
  end

  defp non_negative_number_list_values(value) do
    case numeric_or_nil(value) do
      number when is_number(number) and number >= 0.0 -> {:ok, [number]}
      _other -> :error
    end
  end

  defp map_list_values(values) when is_list(values) do
    if Enum.all?(values, &is_map/1), do: {:ok, values}, else: :error
  end

  defp map_list_values(_values), do: :error

  defp numeric_or_nil(value), do: ExecutionUncertaintyInput.numeric_or_nil(value)
end
