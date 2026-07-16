defmodule OrbitalDynamics.Schema.ValidationReferenceContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation
  alias OrbitalDynamics.Schema.StableIdValidation
  alias OrbitalDynamics.Schema.ValidationPolicyContracts

  def validate_fixture_report(issues, path, artifact, contract) do
    issues
    |> PrimitiveValidation.require_fields(path, artifact, contract["required_fields"])
    |> PrimitiveValidation.expect_equal(
      path,
      artifact,
      "schema_contract",
      "validation_reference_fixture_report.v1"
    )
    |> PrimitiveValidation.expect_one_of(path, artifact, "status", ["pass", "fail"])
    |> PrimitiveValidation.expect_type(path, artifact, "reports", :list)
    |> PrimitiveValidation.expect_type(path, artifact, "fixture_count", :integer)
    |> PrimitiveValidation.expect_field_at_least(path, artifact, "fixture_count", 0)
    |> PrimitiveValidation.expect_optional_type(path, artifact, "status_counts", :map)
    |> PrimitiveValidation.validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(artifact, "status_counts")
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      artifact,
      "fixture_count",
      length(Map.get(artifact, "reports", [])),
      "must equal reports count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      artifact,
      "status",
      fixture_report_status(artifact),
      "must equal nested report statuses"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      artifact,
      "status_counts",
      fixture_report_status_counts(artifact),
      "must equal nested report status counts"
    )
    |> validate_rows(
      path <> ".reports",
      Map.get(artifact, "reports", []),
      &validate_report/3
    )
  end

  def validate_report(issues, path, report) do
    issues
    |> PrimitiveValidation.require_fields(path, report, [
      "schema_contract",
      "fixture_id",
      "model_id",
      "validation_level",
      "status",
      "checks"
    ])
    |> PrimitiveValidation.expect_equal(
      path,
      report,
      "schema_contract",
      "validation_reference_report.v1"
    )
    |> StableIdValidation.validate_stable_ids(path, report, ["fixture_id"])
    |> PrimitiveValidation.expect_type(path, report, "model_id", :binary)
    |> PrimitiveValidation.expect_type(path, report, "validation_level", :binary)
    |> PrimitiveValidation.expect_one_of(
      path,
      report,
      "validation_level",
      ValidationPolicyContracts.level_names()
    )
    |> PrimitiveValidation.expect_one_of(path, report, "status", ["pass", "fail"])
    |> PrimitiveValidation.expect_type(path, report, "checks", :list)
    |> PrimitiveValidation.expect_optional_type(path, report, "status_counts", :map)
    |> PrimitiveValidation.validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(report, "status_counts")
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      report,
      "status",
      report_status(report),
      "must equal nested check statuses"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      report,
      "status_counts",
      report_status_counts(report),
      "must equal nested check status counts"
    )
    |> validate_rows(
      path <> ".checks",
      Map.get(report, "checks", []),
      &validate_check/3
    )
  end

  def validate_check(issues, path, check) do
    issues
    |> PrimitiveValidation.require_fields(path, check, [
      "field",
      "status",
      "expected",
      "observed",
      "tolerance"
    ])
    |> PrimitiveValidation.expect_type(path, check, "field", :binary)
    |> PrimitiveValidation.expect_one_of(path, check, "status", ["pass", "fail"])
    |> PrimitiveValidation.expect_optional_number(path, check, "error")
    |> PrimitiveValidation.expect_optional_number(path, check, "max_abs_error")
    |> validate_check_result(path, check)
  end

  defp fixture_report_status(%{"reports" => reports}) when is_list(reports) do
    if Enum.all?(reports, &(Map.get(&1, "status") == "pass")), do: "pass", else: "fail"
  end

  defp fixture_report_status(_artifact), do: nil

  defp fixture_report_status_counts(%{"reports" => reports}) when is_list(reports) do
    frequency_map(reports, "status")
  end

  defp fixture_report_status_counts(_artifact), do: nil

  defp report_status(%{"checks" => checks}) when is_list(checks) do
    if Enum.all?(checks, &(Map.get(&1, "status") == "pass")), do: "pass", else: "fail"
  end

  defp report_status(_report), do: nil

  defp report_status_counts(%{"checks" => checks}) when is_list(checks) do
    frequency_map(checks, "status")
  end

  defp report_status_counts(_report), do: nil

  defp validate_check_result(issues, path, check) do
    expected = Map.get(check, "expected")
    observed = Map.get(check, "observed")
    tolerance = Map.get(check, "tolerance")

    case check_result(expected, observed, tolerance) do
      {:ok, status, metric_field, metric_value} ->
        issues
        |> PrimitiveValidation.expect_field_equals(
          path,
          check,
          "status",
          status,
          "must match expected/observed/tolerance comparison"
        )
        |> PrimitiveValidation.expect_field_equals(
          path,
          check,
          metric_field,
          metric_value,
          "must match expected/observed comparison error"
        )

      {:ok, status} ->
        PrimitiveValidation.expect_field_equals(
          issues,
          path,
          check,
          "status",
          status,
          "must match expected/observed comparison"
        )
    end
  end

  defp check_result(expected, observed, tolerance)
       when is_number(expected) and is_number(observed) and is_number(tolerance) do
    error = abs(observed - expected)
    {:ok, if(error <= tolerance, do: "pass", else: "fail"), "error", error}
  end

  defp check_result(expected, observed, tolerance)
       when is_list(expected) and is_list(observed) and is_number(tolerance) do
    if numeric_vector?(expected) and numeric_vector?(observed) and
         length(expected) == length(observed) do
      error =
        expected
        |> Enum.zip(observed)
        |> Enum.map(fn {expected_value, observed_value} ->
          abs(observed_value - expected_value)
        end)
        |> Enum.max(fn -> 0.0 end)

      {:ok, if(error <= tolerance, do: "pass", else: "fail"), "max_abs_error", error}
    else
      {:ok, if(observed == expected, do: "pass", else: "fail")}
    end
  end

  defp check_result(expected, observed, _tolerance),
    do: {:ok, if(observed == expected, do: "pass", else: "fail")}

  defp numeric_vector?(values), do: Enum.all?(values, &is_number/1)

  defp frequency_map(rows, field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp validate_rows(issues, path, rows, validator) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      if is_map(row) do
        validator.(acc, "#{path}[#{index}]", row)
      else
        [PrimitiveValidation.error("#{path}[#{index}]", "must be an object") | acc]
      end
    end)
  end

  defp validate_rows(issues, _path, _rows, _validator), do: issues
end
