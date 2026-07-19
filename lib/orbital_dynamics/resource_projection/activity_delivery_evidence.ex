defmodule OrbitalDynamics.ResourceProjection.ActivityDeliveryEvidence do
  @moduledoc false

  def context(activity) do
    collection_ends_at_s =
      first_number([
        activity["collection_ends_at_s"],
        activity["collection_end_s"],
        get_in(activity, ["metadata", "collection_ends_at_s"]),
        get_in(activity, ["metadata", "collection_end_s"])
      ])

    planned_delivery_at_s =
      first_number([
        activity["planned_delivery_at_s"],
        activity["expected_delivery_at_s"],
        activity["delivery_at_s"],
        get_in(activity, ["metadata", "planned_delivery_at_s"]),
        get_in(activity, ["metadata", "expected_delivery_at_s"]),
        get_in(activity, ["metadata", "delivery_at_s"])
      ])

    actual_delivery_at_s =
      first_number([
        activity["actual_delivery_at_s"],
        activity["delivered_at_s"],
        get_in(activity, ["metadata", "actual_delivery_at_s"]),
        get_in(activity, ["metadata", "delivered_at_s"])
      ])

    max_latency_s =
      first_number([
        activity["max_latency_s"],
        activity["latency_requirement_s"],
        get_in(activity, ["metadata", "max_latency_s"]),
        get_in(activity, ["metadata", "latency_requirement_s"])
      ])

    planned_latency_s =
      first_number([
        activity["planned_latency_s"],
        get_in(activity, ["metadata", "planned_latency_s"])
      ]) || latency_between(collection_ends_at_s, planned_delivery_at_s)

    actual_latency_s =
      first_number([
        activity["actual_latency_s"],
        get_in(activity, ["metadata", "actual_latency_s"])
      ]) || latency_between(collection_ends_at_s, actual_delivery_at_s)

    {latency_basis, selected_latency_s} =
      cond do
        is_number(actual_latency_s) -> {"actual", actual_latency_s}
        is_number(planned_latency_s) -> {"planned", planned_latency_s}
        true -> {nil, nil}
      end

    %{
      "collection_ends_at_s" => collection_ends_at_s,
      "planned_delivery_at_s" => planned_delivery_at_s,
      "actual_delivery_at_s" => actual_delivery_at_s,
      "max_latency_s" => max_latency_s,
      "planned_latency_s" => planned_latency_s,
      "actual_latency_s" => actual_latency_s,
      "latency_margin_s" => latency_margin_s(max_latency_s, selected_latency_s),
      "latency_basis" => latency_basis,
      "latency_status" => latency_status(max_latency_s, selected_latency_s),
      "completed_fraction" => completed_fraction(activity)
    }
  end

  defp latency_between(collection_ends_at_s, delivery_at_s)
       when is_number(collection_ends_at_s) and is_number(delivery_at_s),
       do: max(delivery_at_s - collection_ends_at_s, 0.0)

  defp latency_between(_collection_ends_at_s, _delivery_at_s), do: nil

  defp latency_margin_s(max_latency_s, selected_latency_s)
       when is_number(max_latency_s) and is_number(selected_latency_s),
       do: max_latency_s - selected_latency_s

  defp latency_margin_s(_max_latency_s, _selected_latency_s), do: nil

  defp latency_status(max_latency_s, selected_latency_s)
       when is_number(max_latency_s) and is_number(selected_latency_s) do
    if selected_latency_s > max_latency_s, do: "late", else: "within_limit"
  end

  defp latency_status(_max_latency_s, _selected_latency_s), do: nil

  defp completed_fraction(activity) do
    case first_number([
           activity["completed_fraction"],
           activity["completion_fraction"],
           get_in(activity, ["metadata", "completed_fraction"]),
           get_in(activity, ["metadata", "completion_fraction"])
         ]) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp first_number(values), do: Enum.find_value(values, &numeric_or_nil/1)

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil
end
