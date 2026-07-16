defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionReviewRowSources do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionEncoding

  def row_from_review_or_import_row(%{} = row) do
    embedded =
      row
      |> embedded_source_row()
      |> stringify_embedded_source_row()

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("id", row["subject_id"] || row["contact_id"])
    |> Map.put_new("contact_id", row["contact_id"] || row["subject_id"])
    |> Map.put_new("required_operator_action", row["required_operator_action"])
    |> Map.put_new("approval_status", row["approval_status"])
    |> compact_map()
  end

  defp embedded_source_row(row) do
    cond do
      is_map(row["source_contention_group"]) ->
        row["source_contention_group"]

      is_map(get_in(row, ["source_review_row", "source_contention_group"])) ->
        get_in(row, ["source_review_row", "source_contention_group"])

      is_map(row["source_invalid_contact_input"]) ->
        row["source_invalid_contact_input"]

      is_map(get_in(row, ["source_review_row", "source_invalid_contact_input"])) ->
        get_in(row, ["source_review_row", "source_invalid_contact_input"])

      true ->
        %{}
    end
  end

  defp stringify_embedded_source_row(%{} = source_row) do
    ContactContentionEncoding.stringify_keys(source_row)
  end

  defp stringify_embedded_source_row(_source_row), do: %{}
end
