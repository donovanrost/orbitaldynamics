defmodule OrbitalDynamics.CampaignPlanner.OperationalTimelineSourceRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{SourceRowTuples, ValueEncoding}

  def rows_with_source(reports_with_sources),
    do: rows_with_source(reports_with_sources, default_opts())

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

  def rows(reports_with_sources), do: rows(reports_with_sources, default_opts())

  def rows(reports_with_sources, opts) when is_list(opts) do
    reports_with_sources
    |> rows_with_source(opts)
    |> SourceRowTuples.rows()
  end

  def pressure_rows_with_source(reports_with_sources),
    do: pressure_rows_with_source(reports_with_sources, default_opts())

  def pressure_rows_with_source(reports_with_sources, opts) when is_list(opts) do
    reports_with_sources
    |> rows_with_source(opts)
    |> Enum.with_index(1)
    |> Enum.map(fn {{row, source_path}, index} ->
      row =
        row
        |> Map.put_new("review_type", "operational_timeline_review")

      {row, source_path, index}
    end)
  end

  defp default_opts do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      put_if_absent: &put_if_absent/3
    ]
  end

  defp put_if_absent(map, _key, value) when value in [nil, "", [], %{}], do: map

  defp put_if_absent(map, key, value) do
    Map.put_new(map, key, value)
  end
end
