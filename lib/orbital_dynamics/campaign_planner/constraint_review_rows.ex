defmodule OrbitalDynamics.CampaignPlanner.ConstraintReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def source(row), do: source(row, callbacks())

  def source(%{"source_constraint_row" => %{} = source}, _callbacks)
      when map_size(source) > 0,
      do: {source, "source_constraint_row"}

  def source(row, callbacks), do: {flattened_row(row, callbacks), "constraint_review"}

  def flattened_row(row), do: flattened_row(row, callbacks())

  def flattened_row(row, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    row
    |> stringify_keys.()
    |> Map.put_new("status", row["constraint_status"])
  end

  def review_row?(row) do
    (row["source_review_type"] == "constraint_review" or
       row["review_type"] == "constraint_review" or row["import_action"] == "review_constraint") and
      row["metric"] not in [nil, ""]
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end
end
