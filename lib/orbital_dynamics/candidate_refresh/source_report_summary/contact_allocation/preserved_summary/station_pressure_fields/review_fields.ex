defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationPressureFields.ReviewFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sorted_string_values: 1
    ]

  def fields(summary) do
    %{
      "station_pressure_review_contact_ids" => review_contact_ids(summary),
      "station_pressure_contact_count" =>
        numeric_report_count(summary, "station_pressure_contact_count"),
      "station_pressure_review_contact_count" =>
        numeric_report_count(summary, "station_pressure_review_contact_count")
    }
  end

  defp review_contact_ids(summary) do
    if Map.has_key?(summary, "station_pressure_review_contact_ids") do
      sorted_string_values(Map.get(summary, "station_pressure_review_contact_ids", []))
    end
  end
end
