defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessSummaryReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryRecognition

  defdelegate import_readiness_summary?(summary), to: ProviderCounterofferSummaryRecognition

  def report_from_import_readiness_summary(%{} = summary) do
    rows = ProviderCounterofferImportReadinessRows.rows(summary)

    %{
      "schema_contract" => "provider_counteroffer_report.v1",
      "model" => "preserved_provider_counteroffer_import_readiness_summary",
      "source" => Map.get(summary, "source"),
      "source_summary_model" => Map.get(summary, "model"),
      "source_summary_schema_contract" => Map.get(summary, "schema_contract"),
      "source_artifact_type" => Map.get(summary, "source_artifact_type"),
      "source_counteroffer_artifact_type" =>
        Map.get(summary, "source_counteroffer_artifact_type"),
      "source_artifact_id" => Map.get(summary, "source_artifact_id"),
      "import_readiness_summary_count" => 1,
      "import_readiness_status" => Map.get(summary, "import_readiness_status"),
      "import_classification" => Map.get(summary, "import_classification"),
      "assumptions" => Map.get(summary, "assumptions")
    }
    |> Map.merge(ProviderCounterofferImportReadinessRows.report_fields(summary, rows))
    |> maybe_put("provenance", Map.get(summary, "provenance"))
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
