defmodule OrbitalDynamics.CampaignPlanner.OperationalTimelineSourceRows do
  @moduledoc false

  def rows_with_source(reports_with_sources, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    put_if_absent = Keyword.fetch!(opts, :put_if_absent)

    reports_with_sources
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> Map.get("rows", [])
      |> Enum.map(stringify_keys)
      |> Enum.map(fn row ->
        row =
          row
          |> put_if_absent.("trust_boundary", trust_boundary)
          |> Map.put("_source_report_trust_boundary", trust_boundary)

        {row, "#{source_path}.rows"}
      end)
    end)
  end
end
