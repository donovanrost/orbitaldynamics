defmodule OrbitalDynamics.CampaignPlanner.CollectionLatencyObjectives do
  @moduledoc false

  alias OrbitalDynamics.CollectionLatencyObjectiveType

  @latency_limit_fields [
    "max_latency_s",
    "required_latency_s",
    "target_latency_s",
    "latency_limit_s",
    "max_delivery_latency_s",
    "required_delivery_latency_s",
    "target_delivery_latency_s"
  ]

  def objective?(%{"type" => type} = objective) do
    CollectionLatencyObjectiveType.supported?(type) and is_number(limit_s(objective))
  end

  def objective?(_objective), do: false

  def limit_s(objective) do
    Enum.find_value(@latency_limit_fields, fn field ->
      case numeric_or_nil(Map.get(objective, field)) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil
end
