defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.SourceFields.TrustBoundaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      normalize_trust_boundaries: 1,
      source_report_trust_boundaries: 1
    ]

  def values(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&values/1)
    |> normalize_trust_boundaries()
  end

  def values(%{"recommendations" => recommendations} = report)
      when is_list(recommendations) do
    row_trust_boundaries =
      recommendations
      |> Enum.map(&EncodedValue.stringify_keys_with_keyword_maps/1)
      |> Enum.map(&contact_contention_resolution_trust_boundary/1)

    row_trust_boundaries ++ source_report_trust_boundaries([report])
  end

  def values(%{} = report), do: source_report_trust_boundaries([report])
  def values(_report), do: []

  defp contact_contention_resolution_trust_boundary(recommendation) do
    Map.get(recommendation, "trust_boundary") ||
      get_in(recommendation, ["provenance", "trust_boundary"]) ||
      get_in(recommendation, ["source_recommendation", "trust_boundary"]) ||
      get_in(recommendation, ["source_recommendation", "provenance", "trust_boundary"]) ||
      recommendation["_source_report_trust_boundary"]
  end
end
