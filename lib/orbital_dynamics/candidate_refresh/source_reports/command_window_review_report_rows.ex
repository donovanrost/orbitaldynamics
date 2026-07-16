defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewReportRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewRows

  def operator_review_package_rows(package) do
    package
    |> Map.get("rows", [])
    |> rows_matching(&(&1["review_type"] == "command_window_review"))
  end

  def cadence_import_manifest_rows(manifest) do
    manifest
    |> Map.get("rows", [])
    |> rows_matching(fn row ->
      row["source_review_type"] == "command_window_review" or
        row["import_action"] == "review_command_window"
    end)
  end

  def stringify_keys(value), do: CommandWindowReviewRows.stringify_keys(value)

  defp rows_matching(rows, predicate) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(predicate)
    |> Enum.map(&CommandWindowReviewRows.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end
end
