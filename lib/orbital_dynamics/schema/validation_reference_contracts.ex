defmodule OrbitalDynamics.Schema.ValidationReferenceContracts do
  @moduledoc false

  def validate_fixture_report(issues, path, artifact, contract, callbacks)
      when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, artifact, contract["required_fields"])
    |> expect_equal(
      callbacks,
      path,
      artifact,
      "schema_contract",
      "validation_reference_fixture_report.v1"
    )
    |> expect_one_of(callbacks, path, artifact, "status", ["pass", "fail"])
    |> expect_type(callbacks, path, artifact, "reports", :list)
    |> expect_type(callbacks, path, artifact, "fixture_count", :integer)
    |> expect_field_at_least(callbacks, path, artifact, "fixture_count", 0)
    |> expect_optional_type(callbacks, path, artifact, "status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_counts",
      Map.get(artifact, "status_counts")
    )
    |> expect_field_equals(
      callbacks,
      path,
      artifact,
      "fixture_count",
      length(Map.get(artifact, "reports", [])),
      "must equal reports count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      artifact,
      "status",
      fixture_report_status(artifact),
      "must equal nested report statuses"
    )
    |> expect_field_equals(
      callbacks,
      path,
      artifact,
      "status_counts",
      fixture_report_status_counts(artifact),
      "must equal nested report status counts"
    )
    |> validate_rows(
      callbacks,
      path <> ".reports",
      Map.get(artifact, "reports", []),
      &validate_report/4
    )
  end

  def validate_report(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, report, [
      "schema_contract",
      "fixture_id",
      "model_id",
      "validation_level",
      "status",
      "checks"
    ])
    |> expect_equal(callbacks, path, report, "schema_contract", "validation_reference_report.v1")
    |> validate_stable_ids(callbacks, path, report, ["fixture_id"])
    |> expect_type(callbacks, path, report, "model_id", :binary)
    |> expect_type(callbacks, path, report, "validation_level", :binary)
    |> expect_one_of(
      callbacks,
      path,
      report,
      "validation_level",
      validation_level_names(callbacks)
    )
    |> expect_one_of(callbacks, path, report, "status", ["pass", "fail"])
    |> expect_type(callbacks, path, report, "checks", :list)
    |> expect_optional_type(callbacks, path, report, "status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_counts",
      Map.get(report, "status_counts")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status",
      report_status(report),
      "must equal nested check statuses"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status_counts",
      report_status_counts(report),
      "must equal nested check status counts"
    )
    |> validate_rows(
      callbacks,
      path <> ".checks",
      Map.get(report, "checks", []),
      &validate_check/4
    )
  end

  def validate_check(issues, path, check, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, check, [
      "field",
      "status",
      "expected",
      "observed",
      "tolerance"
    ])
    |> expect_type(callbacks, path, check, "field", :binary)
    |> expect_one_of(callbacks, path, check, "status", ["pass", "fail"])
    |> expect_optional_number(callbacks, path, check, "error")
    |> expect_optional_number(callbacks, path, check, "max_abs_error")
    |> validate_check_result(callbacks, path, check)
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

  defp validate_check_result(issues, callbacks, path, check) do
    expected = Map.get(check, "expected")
    observed = Map.get(check, "observed")
    tolerance = Map.get(check, "tolerance")

    case check_result(expected, observed, tolerance) do
      {:ok, status, metric_field, metric_value} ->
        issues
        |> expect_field_equals(
          callbacks,
          path,
          check,
          "status",
          status,
          "must match expected/observed/tolerance comparison"
        )
        |> expect_field_equals(
          callbacks,
          path,
          check,
          metric_field,
          metric_value,
          "must match expected/observed comparison error"
        )

      {:ok, status} ->
        expect_field_equals(
          issues,
          callbacks,
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

  defp validate_rows(issues, callbacks, path, rows, validator) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      if is_map(row) do
        validator.(acc, "#{path}[#{index}]", row, callbacks)
      else
        [error(callbacks, "#{path}[#{index}]", "must be an object") | acc]
      end
    end)
  end

  defp validate_rows(issues, _callbacks, _path, _rows, _validator), do: issues

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_field_at_least(issues, callbacks, path, map, field, min),
    do: apply(Keyword.fetch!(callbacks, :expect_field_at_least), [issues, path, map, field, min])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, map) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [issues, path, map])
  end

  defp validation_level_names(callbacks),
    do: apply(Keyword.fetch!(callbacks, :validation_tolerance_policy_level_names), [])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
