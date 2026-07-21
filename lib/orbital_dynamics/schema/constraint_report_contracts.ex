defmodule OrbitalDynamics.Schema.ConstraintReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  alias OrbitalDynamics.Schema.CollectionAggregation

  def models do
    model_limits_by_model()
    |> Map.keys()
    |> Enum.sort()
  end

  def model_limits_by_model do
    %{
      "artifact_metric_threshold" => artifact_metric_model_limits(),
      "campaign_planner_local_constraint_summary" => campaign_local_model_limits(),
      "campaign_repair_local_constraint_summary" => campaign_local_model_limits()
    }
  end

  def model_limit_values do
    model_limits_by_model()
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  def validate(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "constraint_report.v1")
    |> expect_type(path, report, "model", :binary)
    |> expect_one_of(path, report, "model", models())
    |> expect_non_negative_integer(path, report, "constraint_count")
    |> expect_non_negative_integer(path, report, "row_count")
    |> expect_one_of(path, report, "status", ["pass", "fail", "warning"])
    |> expect_type(path, report, "status_counts", :map)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_model_limits(path, report)
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_rows(path <> ".rows", Map.get(report, "rows", []), &validate_row/3)
    |> validate_counts(path, report)
  end

  defp validate_model_limits(issues, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        expected_limits = Map.get(model_limits_by_model(), report["model"])

        if is_nil(expected_limits) or limits == expected_limits do
          issues
        else
          [error("#{path}.model_limits", "must match constraint report model limits") | issues]
        end

      _value ->
        issues
    end
  end

  defp validate_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    constraint_count = constraint_id_count(rows)
    row_count = length(rows)
    status = report_status(rows)

    issues
    |> validate_constraint_count(path, report, constraint_count)
    |> expect_field_equals(path, report, "row_count", row_count, "must equal #{row_count}")
    |> expect_field_equals(path, report, "status", status, "must equal #{status}")
    |> expect_field_equals(
      path,
      report,
      "status_counts",
      status_counts(rows),
      "must equal row-derived status_counts"
    )
  end

  defp validate_constraint_count(issues, path, %{"model" => model} = report, evaluated_count)
       when model in [
              "campaign_planner_local_constraint_summary",
              "campaign_repair_local_constraint_summary"
            ] do
    case Map.get(report, "constraint_count") do
      count when is_integer(count) and count < evaluated_count ->
        [
          error(
            "#{path}.constraint_count",
            "must be at least the #{evaluated_count} evaluated constraints"
          )
          | issues
        ]

      _count ->
        issues
    end
  end

  defp validate_constraint_count(issues, path, report, constraint_count) do
    expect_field_equals(
      issues,
      path,
      report,
      "constraint_count",
      constraint_count,
      "must equal #{constraint_count}"
    )
  end

  defp constraint_id_count(rows) do
    rows
    |> Enum.map(&Map.get(&1, "constraint_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
  end

  defp report_status(rows) do
    statuses = Enum.map(rows, &Map.get(&1, "status"))

    cond do
      "fail" in statuses -> "fail"
      "warning" in statuses -> "warning"
      true -> "pass"
    end
  end

  defp status_counts(rows) do
    rows
    |> CollectionAggregation.frequency_map("status")
    |> Map.put_new("pass", 0)
    |> Map.put_new("fail", 0)
    |> Map.put_new("warning", 0)
  end

  defp validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "constraint_id",
      "scenario_id",
      "metric",
      "operator",
      "threshold",
      "status"
    ])
    |> validate_stable_ids(path, row, ["constraint_id", "scenario_id"])
    |> expect_one_of(path, row, "operator", ["<", "<=", "==", ">=", ">"])
    |> expect_number(path, row, "threshold")
    |> expect_optional_number(path, row, "value")
    |> expect_optional_number(path, row, "score")
    |> expect_one_of(path, row, "status", ["pass", "fail", "warning"])
  end

  defp artifact_metric_model_limits do
    OrbitalDynamics.Constraints.ArtifactMetric.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp campaign_local_model_limits do
    OrbitalDynamics.Constraints.CampaignLocal.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
