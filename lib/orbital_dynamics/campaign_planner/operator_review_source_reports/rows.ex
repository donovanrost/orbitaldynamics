defmodule OrbitalDynamics.CampaignPlanner.OperatorReviewSourceReports.Rows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalFeedbackNormalization,
    OperationalFeedbackSourceMetadata,
    SourceRowTuples,
    ValueEncoding
  }

  def rows_with_source(packages_with_sources),
    do: rows_with_source(packages_with_sources, default_row_source_callbacks())

  def rows_with_source(packages_with_sources, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    put_if_absent = Keyword.fetch!(opts, :put_if_absent)

    packages_with_sources
    |> Enum.flat_map(fn {package, source_path} ->
      trust_boundary =
        Map.get(package, "trust_boundary") || get_in(package, ["provenance", "trust_boundary"])

      package
      |> Map.get("rows", [])
      |> Enum.map(stringify_keys)
      |> Enum.map(fn row ->
        row =
          row
          |> put_if_absent.("trust_boundary", trust_boundary)
          |> Map.put("_source_report_trust_boundary", trust_boundary)
          |> Map.put("_source_path", "#{source_path}.rows")

        {row, source_path}
      end)
    end)
  end

  def pressure_rows_with_source(packages_with_sources),
    do: pressure_rows_with_source(packages_with_sources, default_row_source_callbacks())

  def pressure_rows_with_source(packages_with_sources, opts) when is_list(opts) do
    packages_with_sources
    |> rows_with_source(opts)
    |> Enum.with_index(1)
    |> Enum.map(fn {{row, source_path}, index} ->
      {row, "#{source_path}.rows", index}
    end)
  end

  def rows(packages_with_sources),
    do: rows(packages_with_sources, default_row_source_callbacks())

  def rows(packages_with_sources, opts) when is_list(opts) do
    packages_with_sources
    |> rows_with_source(opts)
    |> SourceRowTuples.rows()
  end

  def trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  def put_source_report_trust_boundary(%{} = source, row) do
    Map.put(source, "_source_report_trust_boundary", trust_boundary(row))
  end

  def all_operational_feedback_rows(packages_with_sources),
    do: all_operational_feedback_rows(packages_with_sources, default_row_source_callbacks())

  def all_operational_feedback_rows(packages_with_sources, opts) when is_list(opts) do
    packages_with_sources
    |> rows(opts)
    |> Enum.filter(&Map.has_key?(&1, "source_operational_feedback"))
  end

  def operational_feedback_rows(packages_with_sources),
    do:
      operational_feedback_rows(
        packages_with_sources,
        default_operational_feedback_row_callbacks()
      )

  def operational_feedback_rows(packages_with_sources, opts) when is_list(opts) do
    operational_feedback_data_keys = Keyword.fetch!(opts, :operational_feedback_data_keys)

    packages_with_sources
    |> all_operational_feedback_rows(opts)
    |> Enum.filter(fn row ->
      case Map.get(row, "source_operational_feedback") do
        %{} = feedback -> operational_feedback_data_keys.(feedback) != []
        _feedback -> false
      end
    end)
  end

  defp default_row_source_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      put_if_absent: &put_if_absent/3
    ]
  end

  defp default_operational_feedback_row_callbacks do
    default_row_source_callbacks() ++
      [
        operational_feedback_data_keys: &operational_feedback_data_keys/1
      ]
  end

  defp operational_feedback_data_keys(feedback) do
    OperationalFeedbackSourceMetadata.data_keys(
      feedback,
      normalize_operational_feedback: &OperationalFeedbackNormalization.normalize/1
    )
  end

  defp put_if_absent(map, _key, value) when value in [nil, "", [], %{}], do: map

  defp put_if_absent(map, key, value) do
    case Map.get(map, key) do
      existing when existing in [nil, "", [], %{}] -> Map.put(map, key, value)
      _existing -> map
    end
  end
end
