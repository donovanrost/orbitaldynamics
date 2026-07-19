defmodule OrbitalDynamics.OperationalReadiness.QualityGateSchemaValidationSummary do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.EvidenceNormalization

  @schema_contract "operational_quality_gate_schema_validation_summary.v1"

  def schema_contract, do: @schema_contract

  def build(%{} = quality_gate_report) do
    schema_rows = quality_gate_report |> rows() |> schema_validation_rows()
    schema_status_counts = schema_validation_status_counts(schema_rows)
    quality_gate_row_ids_by_status = quality_gate_row_ids_by_status(schema_rows)

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_quality_gate_schema_validation_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => quality_gate_report["source_artifact_type"],
      "source_artifact_id" => quality_gate_report["source_artifact_id"],
      "source_quality_gate_report_id" => quality_gate_report["report_id"],
      "source_readiness_report_id" => quality_gate_report["source_readiness_report_id"],
      "schema_validation_row_count" => length(schema_rows),
      "schema_validation_pass_count" =>
        schema_rows |> Enum.map(&Map.get(&1, "schema_validation_pass_count")) |> integer_sum(),
      "schema_validation_fail_count" =>
        schema_rows |> Enum.map(&Map.get(&1, "schema_validation_fail_count")) |> integer_sum(),
      "schema_validation_error_count" =>
        schema_rows |> Enum.map(&Map.get(&1, "schema_validation_error_count")) |> integer_sum(),
      "schema_validation_warning_count" =>
        schema_rows
        |> Enum.map(&Map.get(&1, "schema_validation_warning_count"))
        |> integer_sum(),
      "schema_validation_remediation_count" =>
        schema_rows
        |> Enum.map(&Map.get(&1, "schema_validation_remediation_count"))
        |> integer_sum(),
      "schema_validation_status_counts" => schema_status_counts,
      "schema_validation_status_ids" => sorted_count_keys(schema_status_counts),
      "schema_validation_import_blocked" => schema_validation_blocked?(schema_rows),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_ids_by_status" => quality_gate_ids_by(schema_rows, "status"),
      "blocked_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("blocked", []),
      "review_required_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("review_required", []),
      "failed_schema_validation_quality_gate_row_ids" =>
        schema_rows
        |> Enum.filter(&schema_validation_failed?/1)
        |> Enum.map(& &1["id"])
        |> stable_sorted_ids(),
      "schema_validation_gate_ids" =>
        schema_rows
        |> Enum.map(& &1["gate_id"])
        |> stable_sorted_ids(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_schema_validation_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_schema_validation_summary_routes_only",
        "quality_gate_schema_validation_summary_does_not_approve_or_import"
      ]
    }
    |> compact_map()
  end

  defp schema_validation_rows(rows) do
    Enum.filter(rows, fn row ->
      row["gate_id"] == "cadence_import" and schema_validation_context?(row)
    end)
  end

  defp schema_validation_context?(row) do
    map_value_count(row["schema_validation_status_counts"]) > 0 or
      Enum.any?(
        ~w(
          schema_validation_pass_count
          schema_validation_fail_count
          schema_validation_error_count
          schema_validation_warning_count
          schema_validation_remediation_count
        ),
        fn field -> integer_value(row[field]) |> positive_integer?() end
      )
  end

  defp schema_validation_status_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "schema_validation_status_counts"))
    |> merge_positive_count_maps()
  end

  defp schema_validation_blocked?(rows), do: Enum.any?(rows, &schema_validation_failed?/1)

  defp schema_validation_failed?(row) do
    integer_value(row["schema_validation_fail_count"]) |> positive_integer?() or
      integer_value(row["schema_validation_error_count"]) |> positive_integer?()
  end

  defp rows(%{"rows" => rows}) when is_list(rows), do: Enum.filter(rows, &is_map/1)
  defp rows(_artifact), do: []

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

  defp integer_sum(values) do
    values
    |> Enum.map(&integer_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  defp positive_integer?(value) when is_integer(value), do: value > 0
  defp positive_integer?(_value), do: false

  defp map_value_count(counts), do: EvidenceNormalization.map_value_count(counts)
  defp integer_value(value), do: EvidenceNormalization.integer_value(value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
