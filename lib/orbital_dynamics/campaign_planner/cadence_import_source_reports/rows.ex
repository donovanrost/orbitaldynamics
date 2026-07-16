defmodule OrbitalDynamics.CampaignPlanner.CadenceImportSourceReports.Rows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    SourceRowTuples,
    ValueEncoding
  }

  def rows_with_source(manifests_with_sources),
    do: rows_with_source(manifests_with_sources, default_row_source_callbacks())

  def rows_with_source(manifests_with_sources, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    cadence_import_trust_boundary = Keyword.fetch!(opts, :cadence_import_trust_boundary)

    manifests_with_sources
    |> Enum.flat_map(fn {manifest, source_path} ->
      manifest_trust_boundary =
        Map.get(manifest, "trust_boundary") || get_in(manifest, ["provenance", "trust_boundary"])

      manifest
      |> Map.get("rows", [])
      |> Enum.map(stringify_keys)
      |> Enum.map(fn row ->
        row =
          row
          |> Map.put(
            "_source_report_trust_boundary",
            cadence_import_trust_boundary.(row, manifest_trust_boundary)
          )
          |> Map.put("_source_path", "#{source_path}.rows")

        {row, source_path}
      end)
    end)
  end

  def rows(manifests_with_sources),
    do: rows(manifests_with_sources, default_row_source_callbacks())

  def rows(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> rows_with_source(opts)
    |> SourceRowTuples.rows()
  end

  def pressure_rows_with_source(manifests_with_sources),
    do: pressure_rows_with_source(manifests_with_sources, default_row_source_callbacks())

  def pressure_rows_with_source(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> rows_with_source(opts)
    |> Enum.with_index(1)
    |> Enum.map(fn {{row, source_path}, index} ->
      {row, "#{source_path}.rows", index}
    end)
  end

  defp default_row_source_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      cadence_import_trust_boundary: &trust_boundary/2
    ]
  end

  def trust_boundary(row, fallback \\ nil) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_review_row", "trust_boundary"]) ||
      get_in(row, ["source_review_row", "provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"] ||
      fallback
  end

  def put_source_report_trust_boundary(%{} = source, row) do
    Map.put(source, "_source_report_trust_boundary", trust_boundary(row))
  end
end
