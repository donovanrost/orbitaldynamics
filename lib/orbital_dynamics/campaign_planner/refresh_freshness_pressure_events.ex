defmodule OrbitalDynamics.CampaignPlanner.RefreshFreshnessPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{RefreshSourceReports, ValueEncoding}

  def source(row), do: source(row, row_callbacks())

  def source(%{"source_freshness_report" => %{} = source} = row, opts)
      when map_size(source) > 0 do
    {pressure_row(source, row, opts), "source_freshness_report"}
  end

  def source(row, opts), do: {pressure_row(row, row, opts), "freshness_review"}

  def pressure_row(source, row), do: pressure_row(source, row, row_callbacks())

  def pressure_row(source, row, opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    put_operator_review_row_fallback = Keyword.fetch!(opts, :put_operator_review_row_fallback)
    put_if_present = Keyword.fetch!(opts, :put_if_present)

    source
    |> stringify_keys.()
    |> put_operator_review_row_fallback.(row, "id", nil)
    |> put_operator_review_row_fallback.(row, "freshness_status", nil)
    |> put_operator_review_row_fallback.(row, "status", "freshness_status")
    |> put_operator_review_row_fallback.(row, "state_quality_status", nil)
    |> put_operator_review_row_fallback.(row, "accepted_snapshot_age_s", nil)
    |> put_operator_review_row_fallback.(row, "horizon_start_offset_s", nil)
    |> put_operator_review_row_fallback.(row, "max_snapshot_age_s", nil)
    |> put_operator_review_row_fallback.(row, "max_horizon_start_offset_s", nil)
    |> put_operator_review_row_fallback.(row, "stale_reasons", nil)
    |> put_operator_review_row_fallback.(row, "unknown_reasons", nil)
    |> put_operator_review_row_fallback.(row, "required_operator_action", nil)
    |> put_if_present.("source_freshness_report", row["source_freshness_report"])
  end

  def review_row?(row) do
    (row["source_review_type"] == "freshness_review" or
       row["review_type"] == "freshness_review" or
       row["import_action"] == "review_refresh_freshness") and
      status(row) in ["stale", "unknown"]
  end

  def pressure_branch(row, source_path, index),
    do: pressure_branch(row, source_path, index, default_callbacks())

  def pressure_branch(row, source_path, index, opts) when is_list(opts) do
    case pressure_event(row, source_path, opts) do
      nil ->
        []

      event ->
        identity = pressure_identity(row, index, opts)

        [
          %{
            "id" => "derived_refresh_freshness_pressure_#{identity}",
            "label" => "Derived refresh-freshness pressure #{identity}",
            "events" => [event],
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_event(row, source_path), do: pressure_event(row, source_path, default_callbacks())

  def pressure_event(row, source_path, opts) when is_list(opts) do
    case status(row) do
      status when status in ["stale", "unknown"] ->
        compact_map = Keyword.fetch!(opts, :compact_map)
        operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)

        %{
          "type" => "refresh_freshness_pressure",
          "freshness_status" => status,
          "state_quality_status" => row["state_quality_status"],
          "accepted_snapshot_age_s" => row["accepted_snapshot_age_s"],
          "horizon_start_offset_s" => row["horizon_start_offset_s"],
          "max_snapshot_age_s" => row["max_snapshot_age_s"],
          "max_horizon_start_offset_s" => row["max_horizon_start_offset_s"],
          "stale_reasons" => row["stale_reasons"],
          "unknown_reasons" => row["unknown_reasons"],
          "required_operator_action" => row["required_operator_action"],
          "derivation_reasons" => ["refresh_freshness_pressure"],
          "feedback_source" => source_path,
          "feedback_scope" => "refresh_freshness",
          "feedback_key" => row["id"] || row["subject_id"] || status,
          "trust_boundary" => operator_review_trust_boundary.(row),
          "source_freshness_report" => Map.get(row, "source_freshness_report", row)
        }
        |> compact_map.()

      _status ->
        nil
    end
  end

  def status(row) do
    row["freshness_status"] ||
      row["status"] ||
      get_in(row, ["source_freshness_report", "freshness_status"]) ||
      get_in(row, ["source_freshness_report", "status"])
  end

  def pressure_branches_from_sources(sources),
    do: pressure_branches_from_sources(sources, default_callbacks())

  def pressure_branches_from_sources(sources, opts) when is_list(opts) do
    sources
    |> RefreshSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      pressure_branch(row, source_path, index, opts)
    end)
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      row["id"],
      row["subject_id"],
      status(row),
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp row_callbacks do
    [
      put_if_present: &put_if_present/3,
      put_operator_review_row_fallback: &put_operator_review_row_fallback/4,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp default_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      put_operator_review_row_fallback: &put_operator_review_row_fallback/4,
      put_if_present: &put_if_present/3,
      operator_review_trust_boundary: &operator_review_trust_boundary/1,
      compact_map: &ValueEncoding.compact_map/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1
    ]
  end

  defp operator_review_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp put_operator_review_row_fallback(source, row, field, row_field) do
    row_field = row_field || field

    case Map.get(source, field) do
      value when value in [nil, ""] -> put_if_present(source, field, row[row_field])
      _value -> source
    end
  end

  defp put_if_present(map, _key, value) when value in [nil, ""], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
end
