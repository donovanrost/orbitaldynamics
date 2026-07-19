defmodule OrbitalDynamics.MissionPlan.Activity.IdentifierInput do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def optional_stable_identifier?(nil), do: true

  def optional_stable_identifier?(value) when is_binary(value),
    do: Regex.match?(@stable_id_pattern, value)

  def optional_stable_identifier?(value) when is_atom(value),
    do: value |> Atom.to_string() |> optional_stable_identifier?()

  def optional_stable_identifier?(_value), do: false

  def optional_dependencies!(nil), do: nil

  def optional_dependencies!(dependencies),
    do: dependencies_input!(dependencies, "dependencies", "activity ids")

  def optional_id_list!(nil, _field, _description), do: nil

  def optional_id_list!(values, field, description),
    do: id_list_input!(values, field, description)

  def optional_identifier!(nil), do: nil

  def optional_identifier!(value) do
    if invalid_identifier?(value) do
      raise ArgumentError, "identifier fields must be non-empty"
    else
      value
    end
  end

  def optional_stable_identifier!(nil, _field), do: nil

  def optional_stable_identifier!(value, field) do
    if optional_stable_identifier?(value) do
      value
    else
      raise ArgumentError, "#{field} must be a stable identifier"
    end
  end

  def valid_dependencies?(dependencies) when is_list(dependencies) do
    match?({:ok, _values}, dependency_values(dependencies))
  end

  def valid_dependencies?(_dependencies), do: false

  def dependencies_input!(values, field, description) do
    case dependency_values(values) do
      {:ok, ids} -> ids
      :error -> raise ArgumentError, "#{field} must be a list of #{description}"
    end
  end

  def dependency_activity_ids(values) when is_list(values) do
    values
    |> Enum.flat_map(&dependency_activity_id_values/1)
    |> Enum.uniq()
  end

  def id_list_input!(values, field, description) do
    case id_list_values(values) do
      {:ok, ids} -> ids
      :error -> raise ArgumentError, "#{field} must be a list of #{description}"
    end
  end

  def required_identifier!(value, field) do
    if invalid_identifier?(value), do: raise(ArgumentError, "#{field} is required"), else: value
  end

  def invalid_identifier?(value), do: value in [nil, ""]

  defp dependency_values(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, ids} ->
      case dependency_values(value) do
        {:ok, value_ids} -> {:cont, {:ok, ids ++ value_ids}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp dependency_values(%{} = value), do: {:ok, [value]}

  defp dependency_values(value) do
    case id_list_value(value) do
      [] -> :error
      ids -> {:ok, ids}
    end
  end

  defp dependency_activity_id_values(%{} = value) do
    [:activity_id, "activity_id", :id, "id"]
    |> Enum.flat_map(fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> Enum.flat_map(nested, &id_list_value/1)
        nested -> id_list_value(nested)
      end
    end)
  end

  defp dependency_activity_id_values(value), do: id_list_value(value)

  defp id_list_values(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, ids} ->
      case id_list_values(value) do
        {:ok, value_ids} -> {:cont, {:ok, ids ++ value_ids}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp id_list_values(value) do
    case id_list_value(value) do
      [] -> :error
      ids -> {:ok, ids}
    end
  end

  defp id_list_value(value) when is_atom(value) and not is_nil(value) do
    string_value = Atom.to_string(value)
    if Regex.match?(@stable_id_pattern, string_value), do: [value], else: []
  end

  defp id_list_value(value) when is_binary(value) do
    values =
      value
      |> String.split(",", trim: false)
      |> Enum.map(&String.trim/1)

    if Enum.all?(values, &stable_id_string?/1), do: values, else: []
  end

  defp id_list_value(_value), do: []

  defp stable_id_string?(value),
    do: value != "" and Regex.match?(@stable_id_pattern, value)
end
