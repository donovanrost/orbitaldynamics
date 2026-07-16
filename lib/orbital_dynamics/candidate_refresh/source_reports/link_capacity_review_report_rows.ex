defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewReportRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewRows

  def operator_review_package_rows(%{} = package) do
    package
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "link_capacity_review"))
    |> Enum.map(&LinkCapacityReviewRows.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  def cadence_import_manifest_rows(%{} = manifest) do
    manifest
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "link_capacity_review" or
        row["import_action"] == "review_link_capacity"
    end)
    |> Enum.map(&LinkCapacityReviewRows.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  defp stringify_keys(value), do: LinkCapacityReviewRows.stringify_keys(value)
end
