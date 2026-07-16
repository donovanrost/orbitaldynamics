defmodule OrbitalDynamics.Schema.ResourceProjectionPressureContracts do
  @moduledoc false

  def pressure_row?(row) do
    Map.get(row, "resource_pressure_types", []) != [] or
      Map.get(row, "resource_pressure_status") in [
        "review_required",
        "storage_overflow",
        "downlink_shortfall",
        "battery_depletion"
      ]
  end

  def types(projected_rows, flow_rows) do
    projected_types =
      projected_rows
      |> Enum.flat_map(fn
        %{} = row -> Map.get(row, "resource_pressure_types", [])
        _row -> []
      end)

    flow_types = Enum.flat_map(flow_rows, &kinds/1)

    (projected_types ++ flow_types)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def kinds(row) do
    []
    |> maybe_add_kind(row, "storage_overflow", "storage_overflow_mb")
    |> maybe_add_kind(row, "downlink_shortfall", "downlink_shortfall_mb")
    |> maybe_add_kind(row, "battery_depletion", "battery_overuse_wh")
    |> maybe_add_availability_kind(row)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp maybe_add_kind(types, row, type, field) do
    case Map.get(row, field) do
      value when is_number(value) and value > 0.0 -> [type | types]
      _value -> types
    end
  end

  defp maybe_add_availability_kind(types, %{"resource_effect_reason" => reason})
       when reason in [
              "spacecraft_unavailable",
              "payload_unavailable",
              "spacecraft_degraded_payload_unavailable",
              "activity_type_suppressed_by_resource_summary",
              "activity_type_incompatible_with_resource_summary",
              "antenna_unavailable"
            ],
       do: [reason | types]

  defp maybe_add_availability_kind(types, _row), do: types
end
