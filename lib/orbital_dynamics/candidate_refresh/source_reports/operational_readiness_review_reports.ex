defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReviewRowReports

  def operator_review_package_report(path, %{} = package) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(&1["review_type"] == "operational_readiness_review"))

    OperationalReadinessReviewRowReports.report_from_review_or_import_rows(
      "#{path}.rows.source_operational_readiness_report",
      rows,
      package
    )
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    rows =
      manifest
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(fn row ->
        row["source_review_type"] == "operational_readiness_review" or
          row["import_action"] == "review_operational_readiness"
      end)

    OperationalReadinessReviewRowReports.report_from_review_or_import_rows(
      "#{path}.rows.source_operational_readiness_report",
      rows,
      manifest
    )
  end

  def stringify_keys(value), do: OperationalReadinessReviewRowReports.stringify_keys(value)
end
