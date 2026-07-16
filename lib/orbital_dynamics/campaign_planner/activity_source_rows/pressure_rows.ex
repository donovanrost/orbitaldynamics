defmodule OrbitalDynamics.CampaignPlanner.ActivitySourceRows.PressureRows do
  @moduledoc false

  def operational_timeline_pressure_rows_with_source(rows_with_sources) do
    rows_with_sources
    |> Enum.with_index(1)
    |> Enum.map(fn {{row, source_path}, index} ->
      row =
        row
        |> Map.put_new("review_type", "operational_timeline_review")

      {row, source_path, index}
    end)
  end

  def realized_activity_pressure_rows_with_source(rows_with_sources) do
    rows_with_sources
    |> Enum.with_index(1)
    |> Enum.map(fn {{row, source_path}, index} ->
      {row, source_path, index}
    end)
  end
end
