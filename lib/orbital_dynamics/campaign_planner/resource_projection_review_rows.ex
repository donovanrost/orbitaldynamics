defmodule OrbitalDynamics.CampaignPlanner.ResourceProjectionReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ResourceProjectionRisk, ScalarValues}

  def source(%{"source_resource_projection" => %{} = source}) when map_size(source) > 0,
    do: {source, "source_resource_projection"}

  def source(row), do: {row, "resource_projection_review"}

  def review_row?(row), do: review_row?(row, callbacks())

  def review_row?(row, callbacks) do
    review_like?(row) and pressure_row?(row, callbacks)
  end

  def review_like?(row) do
    row["source_review_type"] == "resource_projection_review" or
      row["review_type"] == "resource_projection_review" or
      row["import_action"] == "review_resource_projection"
  end

  def pressure_row?(row, callbacks) do
    pressure_types = row |> Map.get("resource_pressure_types", []) |> List.wrap()
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    positive_number? = Keyword.fetch!(callbacks, :positive_number?)

    Enum.any?(
      [
        row["projected_storage_overflow_mb"],
        row["projected_downlink_shortfall_mb"],
        row["projected_battery_overuse_wh"]
      ],
      &(numeric_or_nil.(&1) |> positive_number?.())
    ) or
      thermal_pressure_row?(row, pressure_types, callbacks) or
      Enum.any?(pressure_types, &(&1 in ResourceProjectionRisk.availability_pressure_types()))
  end

  defp thermal_pressure_row?(row, pressure_types, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case numeric_or_nil.(row["thermal_margin_c"]) do
      value when is_number(value) and value < 0.0 -> true
      _value -> "thermal_margin_below_limit" in pressure_types
    end
  end

  defp callbacks do
    [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      positive_number?: &positive_number?/1
    ]
  end

  defp positive_number?(value), do: is_number(value) and value > 0.0
end
