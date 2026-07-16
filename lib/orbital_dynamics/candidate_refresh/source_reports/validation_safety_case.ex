defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ValidationSafetyCase do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ValidationSafetyCaseEncoding

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def report?(%{} = report) do
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)
    status = Map.get(report, "status") || Map.get(report, :status)

    has_safety_case_counts? =
      Enum.any?(
        [
          "evidence_count",
          "evidence_status_counts",
          "evidence_refs_by_status",
          "evidence_refs_by_contract",
          "blocked_evidence_count",
          "review_required_evidence_count",
          "accepted_evidence_count"
        ],
        &Map.has_key?(report, &1)
      )

    schema_contract in [nil, "validation_safety_case_summary.v1"] and
      (status not in [nil, ""] or has_safety_case_counts?)
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: ValidationSafetyCaseEncoding.stringify_keys(value)
end
