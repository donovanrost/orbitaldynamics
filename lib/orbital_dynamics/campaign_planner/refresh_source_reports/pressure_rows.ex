defmodule OrbitalDynamics.CampaignPlanner.RefreshSourceReports.PressureRows do
  @moduledoc false

  def pressure_rows(reports) do
    reports
    |> Enum.with_index(1)
    |> Enum.map(fn {{report, source_path}, index} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      {Map.put(report, "_source_report_trust_boundary", trust_boundary), source_path, index}
    end)
  end
end
