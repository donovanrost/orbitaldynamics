defmodule OrbitalDynamics.CampaignPlanner.LinkCapacityReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.LinkCapacityPressureBranches

  def source(%{"source_link_capacity" => %{} = source}) when map_size(source) > 0,
    do: {source, "source_link_capacity"}

  def source(row), do: {row, "link_capacity_review"}

  def review_row?(row), do: review_row?(row, callbacks())

  def review_row?(row, callbacks) do
    pressure_row? = Keyword.fetch!(callbacks, :pressure_row?)

    (row["source_review_type"] == "link_capacity_review" or
       row["review_type"] == "link_capacity_review" or
       row["import_action"] == "review_link_capacity") and
      pressure_row?.(row)
  end

  defp callbacks, do: [pressure_row?: &LinkCapacityPressureBranches.pressure_row?/1]
end
