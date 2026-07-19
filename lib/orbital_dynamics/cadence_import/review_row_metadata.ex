defmodule OrbitalDynamics.CadenceImport.ReviewRowMetadata do
  @moduledoc false

  def action(row), do: row["action"] || row["required_operator_action"]

  def put_queue(manifest_row, source_row) do
    manifest_row
    |> maybe_put_queue("source_review_queue", source_row["review_queue"])
    |> maybe_put_queue("source_review_queue_key", source_row["review_queue_key"])
  end

  def activity_context(row) do
    row["import_activity_context"] ||
      row["activity_context"] ||
      row["source_activity_context"] ||
      row["replacement_activity_context"]
  end

  defp maybe_put_queue(row, _field, value) when value in [nil, ""], do: row
  defp maybe_put_queue(row, field, value), do: Map.put(row, field, value)
end
