defmodule OrbitalDynamics.Schema.ResourceProjectionNumericContracts do
  @moduledoc false

  def sum_flow_number(flow_rows, field) do
    Enum.reduce(flow_rows, 0, fn row, total ->
      case row do
        %{} ->
          case Map.get(row, field) do
            value when is_number(value) -> total + value
            _value -> total
          end

        _row ->
          total
      end
    end)
  end

  def sum_remaining(rows, capacity_field, used_or_demand_field) do
    rows
    |> remaining_values(capacity_field, used_or_demand_field)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  def min_remaining(rows, capacity_field, used_or_demand_field) do
    rows
    |> remaining_values(capacity_field, used_or_demand_field)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  def max_flow_number(flow_rows, field) do
    flow_rows
    |> flow_number_values(field)
    |> case do
      [] -> 0
      values -> Enum.max(values)
    end
  end

  def max_optional_flow_number(flow_rows, field) do
    flow_rows
    |> flow_number_values(field)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp remaining_values(rows, capacity_field, used_or_demand_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.flat_map(fn row ->
      capacity = Map.get(row, capacity_field)
      used_or_demand = Map.get(row, used_or_demand_field)

      if is_number(capacity) and is_number(used_or_demand) do
        [max(capacity - used_or_demand, 0.0)]
      else
        []
      end
    end)
  end

  defp flow_number_values(flow_rows, field) do
    Enum.flat_map(flow_rows, fn
      %{} = row ->
        case Map.get(row, field) do
          value when is_number(value) -> [value]
          _value -> []
        end

      _row ->
        []
    end)
  end
end
