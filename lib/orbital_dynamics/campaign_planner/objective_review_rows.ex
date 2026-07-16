defmodule OrbitalDynamics.CampaignPlanner.ObjectiveReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def satisfaction_source(row), do: satisfaction_source(row, callbacks())

  def satisfaction_source(%{"source_objective_satisfaction" => %{} = source}, _callbacks)
      when map_size(source) > 0,
      do: {source, "source_objective_satisfaction"}

  def satisfaction_source(row, callbacks),
    do: {flattened_satisfaction_row(row, callbacks), "objective_satisfaction_review"}

  def flattened_satisfaction_row(row), do: flattened_satisfaction_row(row, callbacks())

  def flattened_satisfaction_row(row, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    row
    |> stringify_keys.()
    |> Map.put_new("status", row["objective_status"])
    |> Map.put("id", row["objective_id"] || row["subject_id"] || row["id"])
  end

  def satisfaction_review_row?(row) do
    (row["source_review_type"] == "objective_satisfaction_review" or
       row["review_type"] == "objective_satisfaction_review" or
       row["import_action"] == "review_objective_satisfaction") and
      row["objective"] not in [nil, ""]
  end

  def tradeoff_source(%{"source_objective_tradeoff" => %{} = source})
      when map_size(source) > 0,
      do: {source, "source_objective_tradeoff"}

  def tradeoff_source(row), do: {row, "objective_tradeoff_review"}

  def tradeoff_review_row?(row) do
    row["source_review_type"] == "objective_tradeoff_review" or
      row["review_type"] == "objective_tradeoff_review" or
      row["import_action"] == "review_objective_tradeoff"
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end
end
