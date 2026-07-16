defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ModelAcceptance do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelAcceptanceEncoding

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
    intended_use = Map.get(report, "intended_use") || Map.get(report, :intended_use)
    status = Map.get(report, "status") || Map.get(report, :status)

    has_acceptance_counts? =
      Enum.any?(
        [
          "model_count",
          "accepted_count",
          "review_required_count",
          "blocked_count",
          "unknown_model_count",
          "validation_level_counts",
          "model_ids_by_status",
          "model_ids_by_validation_level",
          "model_ids_by_intended_use"
        ],
        &Map.has_key?(report, &1)
      )

    schema_contract in [nil, "model_acceptance_report.v1"] and
      (intended_use not in [nil, ""] or status not in [nil, ""] or has_acceptance_counts?)
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: ModelAcceptanceEncoding.stringify_keys(value)
end
