defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionReviewReportRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionReviewRows

  def operator_review_package_rows(package) do
    package
    |> Map.get("rows", [])
    |> rows_matching(&(&1["review_type"] == "objective_satisfaction_review"))
  end

  def cadence_import_manifest_rows(manifest) do
    manifest
    |> Map.get("rows", [])
    |> rows_matching(fn row ->
      row["source_review_type"] == "objective_satisfaction_review" or
        row["import_action"] == "review_objective_satisfaction"
    end)
  end

  def stringify_keys(value), do: ObjectiveSatisfactionReviewRows.stringify_keys(value)

  defp rows_matching(rows, predicate) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(predicate)
    |> Enum.map(&ObjectiveSatisfactionReviewRows.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end
end
