defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterEmbeddedRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportValueEncoding

  def row_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_contact_suppression"]) ->
          row["source_contact_suppression"]

        is_map(get_in(row, ["source_review_row", "source_contact_suppression"])) ->
          get_in(row, ["source_review_row", "source_contact_suppression"])

        true ->
          %{}
      end

    embedded =
      case embedded do
        %{} = suppression_row -> stringify_keys(suppression_row)
        _suppression_row -> %{}
      end

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("id", row["activity_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("ground_station_id", row["ground_station_id"])
    |> Map.put_new("suppressed_reason", row["suppressed_reason"] || row["reason"])
    |> compact_map()
  end

  defp stringify_keys(value), do: ContactFilterReportValueEncoding.stringify_keys(value)
end
