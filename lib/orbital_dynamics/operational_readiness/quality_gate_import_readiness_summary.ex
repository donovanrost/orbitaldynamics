defmodule OrbitalDynamics.OperationalReadiness.QualityGateImportReadinessSummary do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.{
    EvidenceNormalization,
    TimelinePublicationContext
  }

  @schema_contract "operational_quality_gate_import_readiness_summary.v1"

  def build(%{} = quality_gate_report) do
    import_rows = quality_gate_report |> rows() |> import_readiness_rows()
    quality_gate_row_ids_by_status = quality_gate_row_ids_by_status(import_rows)

    freshness_status_counts =
      import_rows
      |> Enum.map(&Map.get(&1, "freshness_status_counts"))
      |> merge_positive_count_maps()

    import_status_counts =
      import_rows |> Enum.map(&Map.get(&1, "import_status_counts")) |> merge_positive_count_maps()

    cadence_import_status_counts =
      import_rows
      |> Enum.map(&Map.get(&1, "cadence_import_status_counts"))
      |> merge_positive_count_maps()

    publication_context = TimelinePublicationContext.from_rows(import_rows)

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_quality_gate_import_readiness_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => quality_gate_report["source_artifact_type"],
      "source_artifact_id" => quality_gate_report["source_artifact_id"],
      "source_quality_gate_report_id" => quality_gate_report["report_id"],
      "source_readiness_report_id" => quality_gate_report["source_readiness_report_id"],
      "import_readiness_row_count" => length(import_rows),
      "ready_for_import_count" =>
        import_rows |> Enum.map(&Map.get(&1, "ready_for_import_count")) |> integer_sum(),
      "manifest_review_required_count" =>
        import_rows
        |> Enum.map(&Map.get(&1, "manifest_review_required_count"))
        |> integer_sum(),
      "blocked_import_count" =>
        import_rows |> Enum.map(&Map.get(&1, "blocked_import_count")) |> integer_sum(),
      "missing_import_count" =>
        import_rows |> Enum.map(&Map.get(&1, "missing_import_count")) |> integer_sum(),
      "invalid_cadence_import_count" =>
        import_rows
        |> Enum.map(&Map.get(&1, "invalid_cadence_import_count"))
        |> integer_sum(),
      "current_freshness_count" =>
        import_rows |> Enum.map(&Map.get(&1, "current_freshness_count")) |> integer_sum(),
      "stale_freshness_count" =>
        import_rows |> Enum.map(&Map.get(&1, "stale_freshness_count")) |> integer_sum(),
      "unknown_freshness_count" =>
        import_rows |> Enum.map(&Map.get(&1, "unknown_freshness_count")) |> integer_sum(),
      "freshness_status_counts" => freshness_status_counts,
      "freshness_status_ids" => sorted_count_keys(freshness_status_counts),
      "import_status_counts" => import_status_counts,
      "import_status_ids" => sorted_count_keys(import_status_counts),
      "cadence_import_status_counts" => cadence_import_status_counts,
      "cadence_import_status_ids" => sorted_count_keys(cadence_import_status_counts),
      "freshness_review_required" => freshness_review_required?(import_rows),
      "import_preparation_required" => import_preparation_required?(import_rows),
      "import_blocked" => import_blocked?(import_rows),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_ids_by_status" => quality_gate_ids_by(import_rows, "status"),
      "review_required_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("review_required", []),
      "blocked_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("blocked", []),
      "ready_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("passed", []),
      "analysis_only_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("analysis_only", []),
      "stale_or_unknown_freshness_quality_gate_row_ids" =>
        import_rows
        |> Enum.filter(&freshness_review_required?/1)
        |> Enum.map(& &1["id"])
        |> stable_sorted_ids(),
      "import_preparation_quality_gate_row_ids" =>
        import_rows
        |> Enum.filter(&import_preparation_required?/1)
        |> Enum.map(& &1["id"])
        |> stable_sorted_ids(),
      "blocked_import_quality_gate_row_ids" =>
        import_rows
        |> Enum.filter(&import_blocked?/1)
        |> Enum.map(& &1["id"])
        |> stable_sorted_ids(),
      "import_readiness_gate_ids" =>
        import_rows
        |> Enum.map(& &1["gate_id"])
        |> stable_sorted_ids(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_import_readiness_summary_routes_only",
        "quality_gate_import_readiness_summary_does_not_approve_or_import"
      ]
    }
    |> Map.merge(publication_context)
    |> compact_map()
  end

  defp rows(%{"rows" => rows}) when is_list(rows), do: Enum.filter(rows, &is_map/1)
  defp rows(_artifact), do: []

  defp import_readiness_rows(rows) do
    Enum.filter(rows, fn row ->
      row["gate_id"] == "cadence_import" and import_readiness_context?(row)
    end)
  end

  defp import_readiness_context?(row) do
    map_value_count(row["freshness_status_counts"]) > 0 or
      map_value_count(row["import_status_counts"]) > 0 or
      map_value_count(row["cadence_import_status_counts"]) > 0 or
      Enum.any?(
        ~w(
          ready_for_import_count
          manifest_review_required_count
          blocked_import_count
          missing_import_count
          invalid_cadence_import_count
          current_freshness_count
          stale_freshness_count
          unknown_freshness_count
        ),
        fn field -> integer_value(row[field]) |> positive_integer?() end
      )
  end

  defp freshness_review_required?(rows) when is_list(rows),
    do: Enum.any?(rows, &freshness_review_required?/1)

  defp freshness_review_required?(row) do
    integer_value(row["stale_freshness_count"]) |> positive_integer?() or
      integer_value(row["unknown_freshness_count"]) |> positive_integer?()
  end

  defp import_preparation_required?(rows) when is_list(rows),
    do: Enum.any?(rows, &import_preparation_required?/1)

  defp import_preparation_required?(row) do
    integer_value(row["manifest_review_required_count"]) |> positive_integer?() or
      integer_value(row["missing_import_count"]) |> positive_integer?()
  end

  defp import_blocked?(rows) when is_list(rows), do: Enum.any?(rows, &import_blocked?/1)

  defp import_blocked?(row) do
    integer_value(row["blocked_import_count"]) |> positive_integer?() or
      integer_value(row["invalid_cadence_import_count"]) |> positive_integer?()
  end

  defp positive_integer?(value) when is_integer(value), do: value > 0
  defp positive_integer?(_value), do: false

  defp integer_sum(values) do
    values
    |> Enum.map(&integer_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  defp positive_count_map(%{} = counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value > 0 end)
    |> Map.new()
  end

  defp merge_positive_count_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = counts, acc ->
        counts
        |> positive_count_map()
        |> Enum.reduce(acc, fn {key, count}, inner_acc ->
          Map.update(inner_acc, key, count, &(&1 + count))
        end)

      _counts, acc ->
        acc
    end)
  end

  defp sorted_count_keys(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> stable_sorted_ids()
  end

  defp quality_gate_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["gate_id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp quality_gate_row_ids_by_status(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "status"), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp map_value_count(counts), do: EvidenceNormalization.map_value_count(counts)
  defp integer_value(value), do: EvidenceNormalization.integer_value(value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
