defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowPredicates do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowClassifications,
    as: RowClassifications

  def review_required?(row) do
    normalized_token(Map.get(row, "provider_counteroffer_import_status")) ==
      "review_required_before_import" or
      normalized_token(Map.get(row, "required_operator_action")) in [
        "review_provider_counteroffer",
        "review_required",
        "review_required_before_import"
      ] or Map.get(row, "reviewable") == true
  end

  def import_ready?(row) do
    normalized_token(Map.get(row, "provider_counteroffer_import_status")) in [
      "import_ready",
      "no_import_required"
    ] or
      normalized_token(Map.get(row, "required_operator_action")) in [
        "none",
        "no_import_required"
      ]
  end

  defp normalized_token(value), do: RowClassifications.normalized_token(value)
end
