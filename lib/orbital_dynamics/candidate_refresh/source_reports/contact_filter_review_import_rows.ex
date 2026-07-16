defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReviewImportRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportValueEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterRowReports

  def operator_review_package_rows(%{} = package) do
    package
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "contact_suppression"))
    |> Enum.map(&ContactFilterRowReports.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  def cadence_import_manifest_rows(%{} = manifest) do
    manifest
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "contact_suppression" or
        row["import_action"] == "review_contact_suppression"
    end)
    |> Enum.map(&ContactFilterRowReports.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  defp stringify_keys(value), do: ContactFilterReportValueEncoding.stringify_keys(value)
end
