defmodule OrbitalDynamics.Schema.ValidationAcceptanceReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_array_map: 3, validate_stable_ids: 4]

  alias OrbitalDynamics.Schema.{CollectionValidation, ValidationRecordContracts}

  @safety_case_count_fields [
    "model_accepted_count",
    "model_review_required_count",
    "model_blocked_count",
    "unknown_model_count",
    "readiness_review_required_count",
    "readiness_blocked_count",
    "ready_for_import_count",
    "quality_gate_review_count",
    "quality_gate_blocked_count",
    "schema_error_count",
    "schema_warning_count",
    "schema_validation_report_count",
    "schema_validation_failed_report_count",
    "fixture_passed_count",
    "fixture_failed_count"
  ]

  def safety_case_count_fields, do: @safety_case_count_fields

  def validate_model_acceptance_report(issues, path, report, model_limits) do
    capability = OrbitalDynamics.Validation.capabilities()
    rows = Map.get(report, "rows", [])

    issues
    |> expect_equal(path, report, "schema_contract", "model_acceptance_report.v1")
    |> expect_equal(path, report, "schema_version", 1)
    |> validate_stable_ids(path, report, ["report_id"])
    |> expect_equal(path, report, "model", "registry_model_acceptance_classifier")
    |> expect_one_of(path, report, "intended_use", capability.intended_uses)
    |> expect_one_of(path, report, "status", capability.acceptance_statuses)
    |> expect_non_negative_integer(path, report, "model_count")
    |> expect_non_negative_integer(path, report, "accepted_count")
    |> expect_non_negative_integer(path, report, "review_required_count")
    |> expect_non_negative_integer(path, report, "blocked_count")
    |> expect_non_negative_integer(path, report, "unknown_model_count")
    |> expect_optional_type(path, report, "status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(report, "status_counts")
    )
    |> expect_type(path, report, "validation_level_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".validation_level_counts",
      Map.get(report, "validation_level_counts")
    )
    |> expect_optional_type(path, report, "model_ids_by_status", :map)
    |> expect_field_equals(
      path,
      report,
      "model_ids_by_status",
      model_acceptance_model_ids_by(rows, "status"),
      "must match model IDs grouped by row status"
    )
    |> expect_optional_type(path, report, "model_ids_by_validation_level", :map)
    |> expect_field_equals(
      path,
      report,
      "model_ids_by_validation_level",
      model_acceptance_model_ids_by(rows, "validation_level"),
      "must match model IDs grouped by validation level"
    )
    |> expect_optional_type(path, report, "model_ids_by_intended_use", :map)
    |> expect_field_equals(
      path,
      report,
      "model_ids_by_intended_use",
      model_acceptance_model_ids_by_intended_use(rows, Map.get(report, "intended_use")),
      "must match model IDs grouped by intended use"
    )
    |> expect_type(path, report, "records", :list)
    |> CollectionValidation.validate_rows(
      path <> ".records",
      Map.get(report, "records", []),
      &ValidationRecordContracts.validate(&1, &2, &3)
    )
    |> validate_model_acceptance_records(path, report)
    |> expect_type(path, report, "rows", :list)
    |> CollectionValidation.validate_rows(
      path <> ".rows",
      rows,
      &validate_model_acceptance_row(&1, &2, &3)
    )
    |> expect_type(path, report, "assumptions", :map)
    |> validate_model_acceptance_assumptions(path, report, rows)
    |> expect_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      model_limits,
      "must match model acceptance report model limits"
    )
    |> expect_field_equals(
      path,
      report,
      "status",
      model_acceptance_report_status(rows),
      "must match row-derived model acceptance status"
    )
    |> expect_field_equals(
      path,
      report,
      "model_count",
      if(is_list(rows), do: length(rows))
    )
    |> expect_field_equals(
      path,
      report,
      "accepted_count",
      model_acceptance_row_status_count(rows, "accepted")
    )
    |> expect_field_equals(
      path,
      report,
      "review_required_count",
      model_acceptance_row_status_count(rows, "review_required")
    )
    |> expect_field_equals(
      path,
      report,
      "blocked_count",
      model_acceptance_row_status_count(rows, "blocked")
    )
    |> expect_field_equals(
      path,
      report,
      "unknown_model_count",
      model_acceptance_unknown_model_count(rows)
    )
    |> expect_field_equals(
      path,
      report,
      "status_counts",
      if(is_list(rows), do: frequency_map(rows, "status")),
      "must match row-derived status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "validation_level_counts",
      if(is_list(rows), do: frequency_map(rows, "validation_level")),
      "must match row-derived validation_level_counts"
    )
  end

  def validate_validation_safety_case_summary(issues, path, report, model_limits) do
    capability = OrbitalDynamics.Validation.capabilities()
    rows = Map.get(report, "evidence", [])

    issues
    |> expect_equal(
      path,
      report,
      "schema_contract",
      "validation_safety_case_summary.v1"
    )
    |> expect_equal(path, report, "schema_version", 1)
    |> validate_stable_ids(path, report, ["summary_id"])
    |> expect_equal(
      path,
      report,
      "model",
      "artifact_only_validation_safety_case_summary"
    )
    |> expect_equal(path, report, "source", "validation.safety_case_evidence")
    |> expect_one_of(path, report, "status", capability.safety_case_statuses)
    |> expect_non_negative_integer(path, report, "evidence_count")
    |> expect_non_negative_integer(path, report, "blocked_evidence_count")
    |> expect_non_negative_integer(path, report, "review_required_evidence_count")
    |> expect_non_negative_integer(path, report, "accepted_evidence_count")
    |> expect_type(path, report, "assumptions", :map)
    |> expect_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      model_limits,
      "must match validation safety case summary model limits"
    )
    |> expect_optional_type(path, report, "input_contracts", :list)
    |> validate_string_list_items(path, report, "input_contracts")
    |> expect_optional_type(path, report, "evidence_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".evidence_status_counts",
      Map.get(report, "evidence_status_counts")
    )
    |> expect_optional_type(path, report, "evidence_refs_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".evidence_refs_by_status",
      Map.get(report, "evidence_refs_by_status")
    )
    |> expect_optional_type(path, report, "evidence_refs_by_contract", :map)
    |> validate_stable_id_array_map(
      path <> ".evidence_refs_by_contract",
      Map.get(report, "evidence_refs_by_contract")
    )
    |> validate_safety_case_count_fields(path, report)
    |> expect_optional_type(path, report, "evidence", :list)
    |> CollectionValidation.validate_optional_rows(
      path <> ".evidence",
      rows,
      &validate_safety_case_evidence_row(&1, &2, &3)
    )
    |> expect_field_equals(
      path,
      report,
      "evidence_count",
      safety_case_evidence_count(rows)
    )
    |> expect_field_equals(path, report, "status", safety_case_status(rows))
    |> expect_field_equals(
      path,
      report,
      "input_contracts",
      safety_case_input_contracts(rows),
      "must match evidence schema contracts"
    )
    |> expect_field_equals(
      path,
      report,
      "evidence_status_counts",
      safety_case_status_counts(rows),
      "must match evidence row statuses"
    )
    |> expect_field_equals(
      path,
      report,
      "evidence_refs_by_status",
      safety_case_evidence_refs_by(rows, "status"),
      "must match evidence refs grouped by status"
    )
    |> expect_field_equals(
      path,
      report,
      "evidence_refs_by_contract",
      safety_case_evidence_refs_by(rows, "schema_contract"),
      "must match evidence refs grouped by contract"
    )
    |> expect_field_equals(
      path,
      report,
      "blocked_evidence_count",
      safety_case_status_count(rows, "blocked")
    )
    |> expect_field_equals(
      path,
      report,
      "review_required_evidence_count",
      safety_case_status_count(rows, "review_required")
    )
    |> expect_field_equals(
      path,
      report,
      "accepted_evidence_count",
      safety_case_status_count(rows, "accepted_for_use")
    )
    |> validate_safety_case_aggregate_counts(path, report, rows)
  end

  defp validate_model_acceptance_records(issues, path, report) do
    records = Map.get(report, "records")
    rows = Map.get(report, "rows")

    if is_list(records) and is_list(rows) do
      record_ids =
        records
        |> Enum.filter(&is_map/1)
        |> Enum.map(&Map.get(&1, "id"))
        |> Enum.reject(&is_nil/1)

      row_record_ids =
        rows
        |> Enum.filter(&is_map/1)
        |> Enum.map(&get_in(&1, ["validation_record", "id"]))
        |> Enum.reject(&is_nil/1)

      if record_ids == row_record_ids do
        issues
      else
        [error(path <> ".records", "must match row validation_record IDs") | issues]
      end
    else
      issues
    end
  end

  defp validate_model_acceptance_assumptions(issues, path, report, rows)
       when is_list(rows) do
    case Map.get(report, "assumptions") do
      %{} = assumptions ->
        model_ids =
          rows
          |> Enum.filter(&is_map/1)
          |> Enum.map(&Map.get(&1, "model_id"))
          |> Enum.reject(&is_nil/1)

        issues
        |> expect_field_equals(
          path <> ".assumptions",
          assumptions,
          "intended_use",
          Map.get(report, "intended_use"),
          "must match report intended_use"
        )
        |> expect_field_equals(
          path <> ".assumptions",
          assumptions,
          "input_model_ids",
          model_ids,
          "must match row model IDs"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_model_acceptance_assumptions(issues, _path, _report, _rows),
    do: issues

  defp model_acceptance_report_status(rows) when is_list(rows) do
    cond do
      model_acceptance_row_status_count(rows, "blocked") > 0 -> "blocked"
      model_acceptance_row_status_count(rows, "review_required") > 0 -> "review_required"
      true -> "accepted_for_use"
    end
  end

  defp model_acceptance_report_status(_rows), do: nil

  defp validate_model_acceptance_row(issues, path, row) do
    capability = OrbitalDynamics.Validation.capabilities()

    issues
    |> require_fields(path, row, [
      "id",
      "rank",
      "model_id",
      "validation_level",
      "status",
      "reason"
    ])
    |> validate_stable_ids(path, row, ["id", "model_id"])
    |> expect_non_negative_integer(path, row, "rank")
    |> expect_type(path, row, "validation_level", :binary)
    |> expect_one_of(path, row, "status", capability.row_statuses)
    |> expect_type(path, row, "reason", :binary)
    |> expect_optional_type(path, row, "implementation", :binary)
    |> expect_optional_type(path, row, "validation_record", :map)
    |> validate_optional_model_acceptance_record(
      path,
      Map.get(row, "validation_record")
    )
  end

  defp validate_optional_model_acceptance_record(issues, __path, nil), do: issues

  defp validate_optional_model_acceptance_record(issues, path, %{} = record) do
    ValidationRecordContracts.validate(issues, path <> ".validation_record", record)
  end

  defp validate_optional_model_acceptance_record(issues, path, _record) do
    [error(path <> ".validation_record", "must be an object") | issues]
  end

  defp model_acceptance_row_status_count(rows, status) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  defp model_acceptance_row_status_count(_rows, _status), do: nil

  defp model_acceptance_unknown_model_count(rows) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.count(&(Map.get(&1, "validation_level") == "unknown"))
  end

  defp model_acceptance_unknown_model_count(_rows), do: nil

  defp model_acceptance_model_ids_by(rows, field) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(
      &(Map.get(&1, field) || "unknown"),
      &Map.get(&1, "model_id")
    )
    |> Map.new(fn {value, model_ids} ->
      {to_string(value), Enum.reject(model_ids, &is_nil/1)}
    end)
  end

  defp model_acceptance_model_ids_by(_rows, _field), do: nil

  defp model_acceptance_model_ids_by_intended_use(rows, intended_use) when is_list(rows) do
    model_ids =
      rows
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, "model_id"))
      |> Enum.reject(&is_nil/1)

    %{to_string(intended_use || "unknown") => model_ids}
  end

  defp model_acceptance_model_ids_by_intended_use(_rows, _intended_use), do: nil

  defp validate_safety_case_evidence_row(issues, path, row) do
    capability = OrbitalDynamics.Validation.capabilities()

    issues
    |> require_fields(path, row, ["schema_contract", "status", "rank", "evidence_ref"])
    |> expect_type(path, row, "schema_contract", :binary)
    |> expect_one_of(path, row, "status", capability.safety_case_statuses)
    |> expect_non_negative_integer(path, row, "rank")
    |> validate_stable_ids(path, row, ["evidence_ref"])
    |> expect_optional_type(path, row, "status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(row, "status_counts")
    )
    |> expect_optional_type(path, row, "model_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".model_ids_by_status",
      Map.get(row, "model_ids_by_status")
    )
    |> expect_optional_type(path, row, "model_ids_by_validation_level", :map)
    |> validate_stable_id_array_map(
      path <> ".model_ids_by_validation_level",
      Map.get(row, "model_ids_by_validation_level")
    )
    |> expect_optional_type(path, row, "model_ids_by_intended_use", :map)
    |> validate_stable_id_array_map(
      path <> ".model_ids_by_intended_use",
      Map.get(row, "model_ids_by_intended_use")
    )
    |> validate_safety_case_count_fields(path, row)
    |> validate_safety_case_model_acceptance_status_counts(path, row)
    |> validate_safety_case_operational_readiness_status(path, row)
    |> validate_safety_case_quality_gate_status(path, row)
    |> validate_safety_case_schema_validation_status(path, row)
    |> validate_safety_case_schema_validation_batch_status(path, row)
    |> validate_safety_case_validation_fixture_status(path, row)
  end

  defp validate_safety_case_model_acceptance_status_counts(
         issues,
         path,
         %{"schema_contract" => "model_acceptance_report.v1"} = row
       ) do
    expected =
      [
        {"accepted", Map.get(row, "model_accepted_count")},
        {"review_required", Map.get(row, "model_review_required_count")},
        {"blocked", Map.get(row, "model_blocked_count")}
      ]
      |> Enum.filter(fn {_status, count} -> is_integer(count) and count > 0 end)
      |> Map.new()

    expect_field_equals(
      issues,
      path,
      row,
      "status_counts",
      expected,
      "must match model acceptance evidence counts"
    )
    |> validate_safety_case_model_acceptance_model_ids_by_status(path, row, expected)
  end

  defp validate_safety_case_model_acceptance_status_counts(issues, _path, _row),
    do: issues

  defp validate_safety_case_model_acceptance_model_ids_by_status(
         issues,
         path,
         %{"model_ids_by_status" => model_ids_by_status},
         expected_counts
       )
       when is_map(model_ids_by_status) do
    actual_counts =
      model_ids_by_status
      |> Enum.map(fn {status, ids} ->
        if is_list(ids) do
          {status, length(ids)}
        else
          {status, nil}
        end
      end)
      |> Enum.reject(fn {_status, count} -> is_nil(count) end)
      |> Map.new()

    if actual_counts == expected_counts do
      issues
    else
      [
        error(
          "#{path}.model_ids_by_status",
          "must match model acceptance evidence status counts"
        )
        | issues
      ]
    end
  end

  defp validate_safety_case_model_acceptance_model_ids_by_status(
         issues,
         _path,
         _row,
         _expected_counts
       ),
       do: issues

  defp validate_safety_case_operational_readiness_status(
         issues,
         path,
         %{"schema_contract" => "operational_readiness_report.v1"} = row
       ) do
    expected =
      cond do
        safety_case_positive_count?(Map.get(row, "readiness_blocked_count")) ->
          "blocked"

        safety_case_positive_count?(Map.get(row, "readiness_review_required_count")) ->
          "review_required"

        true ->
          "accepted_for_use"
      end

    expect_field_equals(
      issues,
      path,
      row,
      "status",
      expected,
      "must match operational-readiness evidence counts"
    )
  end

  defp validate_safety_case_operational_readiness_status(issues, _path, _row),
    do: issues

  defp validate_safety_case_quality_gate_status(
         issues,
         path,
         %{"schema_contract" => "quality_gate_report.v1"} = row
       ) do
    expected =
      cond do
        safety_case_positive_count?(Map.get(row, "quality_gate_blocked_count")) ->
          "blocked"

        safety_case_positive_count?(Map.get(row, "quality_gate_review_count")) ->
          "review_required"

        true ->
          "accepted_for_use"
      end

    expect_field_equals(
      issues,
      path,
      row,
      "status",
      expected,
      "must match quality-gate evidence counts"
    )
  end

  defp validate_safety_case_quality_gate_status(issues, _path, _row), do: issues

  defp validate_safety_case_schema_validation_status(
         issues,
         path,
         %{"schema_contract" => "schema_validation_report.v1"} = row
       ) do
    expected =
      cond do
        safety_case_positive_count?(Map.get(row, "schema_error_count")) -> "blocked"
        safety_case_positive_count?(Map.get(row, "schema_warning_count")) -> "review_required"
        true -> "accepted_for_use"
      end

    expect_field_equals(
      issues,
      path,
      row,
      "status",
      expected,
      "must match schema-validation evidence counts"
    )
  end

  defp validate_safety_case_schema_validation_status(issues, _path, _row),
    do: issues

  defp validate_safety_case_schema_validation_batch_status(
         issues,
         path,
         %{"schema_contract" => "schema_validation_batch_report.v1"} = row
       ) do
    expected =
      cond do
        safety_case_positive_count?(Map.get(row, "schema_validation_failed_report_count")) ->
          "blocked"

        safety_case_positive_count?(Map.get(row, "schema_warning_count")) ->
          "review_required"

        true ->
          "accepted_for_use"
      end

    expect_field_equals(
      issues,
      path,
      row,
      "status",
      expected,
      "must match schema-validation batch evidence counts"
    )
  end

  defp validate_safety_case_schema_validation_batch_status(issues, _path, _row),
    do: issues

  defp validate_safety_case_validation_fixture_status(
         issues,
         path,
         %{"schema_contract" => "validation_reference_fixture_report.v1"} = row
       ) do
    expected =
      if safety_case_positive_count?(Map.get(row, "fixture_failed_count")) do
        "blocked"
      else
        "accepted_for_use"
      end

    expect_field_equals(
      issues,
      path,
      row,
      "status",
      expected,
      "must match validation-fixture evidence counts"
    )
  end

  defp validate_safety_case_validation_fixture_status(issues, _path, _row),
    do: issues

  defp safety_case_positive_count?(count), do: is_integer(count) and count > 0

  defp validate_safety_case_count_fields(issues, path, row) do
    Enum.reduce(@safety_case_count_fields, issues, fn field, acc ->
      if Map.has_key?(row, field) do
        expect_non_negative_integer(acc, path, row, field)
      else
        acc
      end
    end)
  end

  defp validate_safety_case_aggregate_counts(issues, path, report, rows) do
    Enum.reduce(@safety_case_count_fields, issues, fn field, acc ->
      expect_field_equals(acc, path, report, field, safety_case_sum(rows, field))
    end)
  end

  defp safety_case_evidence_count(rows) when is_list(rows), do: length(rows)
  defp safety_case_evidence_count(_rows), do: nil

  defp safety_case_status([]), do: "missing_evidence"

  defp safety_case_status(rows) when is_list(rows) do
    statuses = rows |> map_rows() |> Enum.map(&Map.get(&1, "status"))

    cond do
      "blocked" in statuses -> "blocked"
      "review_required" in statuses -> "review_required"
      true -> "accepted_for_use"
    end
  end

  defp safety_case_status(_rows), do: nil

  defp safety_case_input_contracts(rows) when is_list(rows) and rows != [] do
    rows
    |> map_rows()
    |> Enum.map(&Map.get(&1, "schema_contract"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp safety_case_input_contracts(rows) when is_list(rows), do: nil
  defp safety_case_input_contracts(_rows), do: nil

  defp safety_case_status_counts(rows) when is_list(rows) and rows != [] do
    rows
    |> map_rows()
    |> Enum.map(&Map.get(&1, "status"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp safety_case_status_counts(rows) when is_list(rows), do: nil
  defp safety_case_status_counts(_rows), do: nil

  defp safety_case_status_count(rows, status) when is_list(rows) do
    rows
    |> map_rows()
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  defp safety_case_status_count(_rows, _status), do: nil

  defp safety_case_evidence_refs_by(rows, field) when is_list(rows) and rows != [] do
    rows
    |> map_rows()
    |> Enum.group_by(
      &(Map.get(&1, field) || "unknown"),
      &Map.get(&1, "evidence_ref")
    )
    |> Map.new(fn {value, refs} ->
      {to_string(value), Enum.reject(refs, &is_nil/1)}
    end)
  end

  defp safety_case_evidence_refs_by(rows, _field) when is_list(rows), do: nil
  defp safety_case_evidence_refs_by(_rows, _field), do: nil

  defp safety_case_sum(rows, field) when is_list(rows) do
    rows
    |> map_rows()
    |> Enum.map(fn row ->
      case Map.get(row, field) do
        value when is_integer(value) and value >= 0 -> value
        _value -> 0
      end
    end)
    |> Enum.sum()
  end

  defp safety_case_sum(_rows, _field), do: nil

  defp frequency_map(rows, field) do
    rows
    |> map_rows()
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp map_rows(rows), do: Enum.filter(rows, &is_map/1)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
