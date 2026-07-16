defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryRecognition do
  @moduledoc false

  def review_summary?(summary) do
    summary?(
      summary,
      "provider_counteroffer_review_summary.v1",
      "artifact_only_provider_counteroffer_review_summary",
      "review_rows"
    )
  end

  def import_readiness_summary?(summary) do
    summary?(
      summary,
      "provider_counteroffer_import_readiness_summary.v1",
      "artifact_only_provider_counteroffer_import_readiness_summary",
      "import_readiness_rows"
    )
  end

  def plan_impact_summary?(summary) do
    summary?(
      summary,
      "provider_counteroffer_plan_impact_summary.v1",
      "artifact_only_provider_counteroffer_plan_impact_summary",
      "impact_rows"
    )
  end

  defp summary?(%{} = summary, schema_contract, model, rows_field) do
    schema_contract(summary) in [nil, schema_contract] and
      model(summary) == model and is_list(rows(summary, rows_field))
  end

  defp summary?(_summary, _schema_contract, _model, _rows_field), do: false

  defp schema_contract(summary) do
    Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
  end

  defp model(summary) do
    Map.get(summary, "model") || Map.get(summary, :model)
  end

  defp rows(summary, rows_field) do
    Map.get(summary, rows_field) || Map.get(summary, atom_rows_field(rows_field))
  end

  defp atom_rows_field("review_rows"), do: :review_rows
  defp atom_rows_field("impact_rows"), do: :impact_rows
  defp atom_rows_field("import_readiness_rows"), do: :import_readiness_rows
end
