defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewPackageRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewRowReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewValues

  def operator_review_rows(%{} = package) do
    package
    |> Map.get("rows", [])
    |> Enum.map(&ManeuverReviewValues.stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "maneuver_review"))
    |> normalized_rows()
  end

  def cadence_import_rows(%{} = manifest) do
    manifest
    |> Map.get("rows", [])
    |> Enum.map(&ManeuverReviewValues.stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "maneuver_review" or
        row["import_action"] == "review_maneuver"
    end)
    |> normalized_rows()
  end

  defp normalized_rows(rows) do
    rows
    |> Enum.map(&ManeuverReviewRowReports.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end
end
