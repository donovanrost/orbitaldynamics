defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentReviewRowFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentEntryEncoding

  def intent_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_contact_intent"]) ->
          row["source_contact_intent"]

        is_map(get_in(row, ["source_review_row", "source_contact_intent"])) ->
          get_in(row, ["source_review_row", "source_contact_intent"])

        true ->
          %{}
      end

    embedded =
      case embedded do
        %{} = intent -> stringify_keys(intent)
        _intent -> %{}
      end

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("schema_contract", "contact_intent.v1")
    |> Map.put_new("id", row["activity_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("activity_id", row["activity_id"] || row["subject_id"])
    |> Map.put_new("activity_type", row["activity_type"])
    |> Map.put_new("direction", row["direction"])
    |> compact_map()
  end

  def stringify_keys(value), do: ContactIntentEntryEncoding.stringify_keys(value)
end
