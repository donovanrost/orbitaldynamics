defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.BaseFields do
  @moduledoc false

  alias __MODULE__.ContactFields
  alias __MODULE__.CountFields
  alias __MODULE__.Rows

  def fields(summary) do
    rows = Rows.summary_rows(summary)
    review_rows = Rows.review_rows(summary)

    %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "preserved_contact_allocation_summary",
      "source" => Map.get(summary, "source"),
      "source_summary_model" => Map.get(summary, "model"),
      "source_summary_schema_contract" => Map.get(summary, "schema_contract"),
      "source_artifact_type" => Map.get(summary, "source_artifact_type"),
      "rows" => rows,
      "review_rows" => review_rows
    }
    |> Map.merge(CountFields.fields(summary, rows, review_rows))
    |> Map.merge(ContactFields.fields(summary))
    |> maybe_put("provenance", Map.get(summary, "provenance"))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
