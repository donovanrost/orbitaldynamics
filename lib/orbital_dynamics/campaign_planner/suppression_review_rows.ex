defmodule OrbitalDynamics.CampaignPlanner.SuppressionReviewRows do
  @moduledoc false

  def contact_source(%{"source_contact_suppression" => %{} = source})
      when map_size(source) > 0,
      do: {source, "source_contact_suppression"}

  def contact_source(row), do: {row, "contact_suppression"}

  def contact_review_row?(row), do: contact_review_row?(row, callbacks())

  def contact_review_row?(row, callbacks) do
    contact_id = Keyword.fetch!(callbacks, :contact_id)

    (row["source_review_type"] == "contact_suppression" or
       row["review_type"] == "contact_suppression" or
       row["import_action"] == "review_contact_suppression") and
      contact_id.(row) not in [nil, ""] and
      row["suppressed_reason"] not in [nil, ""]
  end

  def resource_source(%{"source_resource_suppression" => %{} = source})
      when map_size(source) > 0,
      do: {source, "source_resource_suppression"}

  def resource_source(row), do: {row, "resource_suppression"}

  def resource_review_row?(row), do: resource_review_row?(row, callbacks())

  def resource_review_row?(row, callbacks) do
    candidate_id = Keyword.fetch!(callbacks, :candidate_id)

    (row["source_review_type"] == "resource_suppression" or
       row["review_type"] == "resource_suppression" or
       row["import_action"] == "review_resource_suppression") and
      candidate_id.(row) not in [nil, ""] and
      row["suppressed_reason"] not in [nil, ""]
  end

  defp callbacks do
    [
      contact_id: &contact_id/1,
      candidate_id: &candidate_id/1
    ]
  end

  defp contact_id(row), do: row["contact_id"] || row["id"] || row["activity_id"]

  defp candidate_id(row), do: row["activity_id"] || row["contact_id"] || row["id"]
end
