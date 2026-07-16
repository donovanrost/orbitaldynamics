defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  alias __MODULE__.Fields
  alias __MODULE__.RowData

  def report_from_summary(%{} = summary) do
    row_data = RowData.prepare(summary)

    %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "preserved_contact_allocation_provider_reservation_request_summary",
      "source" => Map.get(summary, "source"),
      "source_summary_model" => Map.get(summary, "model"),
      "source_summary_schema_contract" => Map.get(summary, "schema_contract"),
      "source_summary_full_rows_present" => row_data.source_summary_full_rows_present?,
      "source_artifact_type" => Map.get(summary, "source_artifact_type"),
      "rows" => Map.get(row_data.derived_summary, "rows", row_data.rows)
    }
    |> Map.merge(
      Fields.fields(
        row_data.derived_summary,
        row_data.provider_reservation_request_rows,
        row_data.provider_reservation_review_rows
      )
    )
    |> maybe_put("provenance", Map.get(summary, "provenance"))
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
