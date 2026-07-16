defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentReviewRowFields

  def operator_review_package_intents(%{} = package) do
    package
    |> Map.get("rows", [])
    |> Enum.map(&ContactIntentReviewRowFields.stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "contact_intent_review"))
    |> Enum.map(&intent_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  def cadence_import_manifest_intents(%{} = manifest) do
    manifest
    |> Map.get("rows", [])
    |> Enum.map(&ContactIntentReviewRowFields.stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "contact_intent_review" or
        row["import_action"] == "review_contact_intent"
    end)
    |> Enum.map(&intent_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  defp intent_from_review_or_import_row(row) do
    ContactIntentReviewRowFields.intent_from_review_or_import_row(row)
  end
end
