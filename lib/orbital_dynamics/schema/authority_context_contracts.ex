defmodule OrbitalDynamics.Schema.AuthorityContextContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @identity_pattern "^authority_context:[0-9a-f]{64}$"
  @propagation_fields ~w(eligibility_status authority_context authority_context_evaluation)
  @evidence_propagation_fields ~w(authority_context authority_context_evaluation)

  def validate(issues, path, context) do
    case OrbitalDynamics.AuthorityContext.validate(context) do
      {:ok, _context} ->
        issues

      {:error, failure} ->
        validation_errors =
          Map.get(failure, "validation_errors", [
            %{"path" => "$", "reason" => failure["reason"]}
          ])

        Enum.reduce(validation_errors, issues, fn validation_error, acc ->
          relative_path = validation_error["path"] |> to_string() |> String.trim_leading("$")
          [error(path <> relative_path, validation_error["reason"]) | acc]
        end)
    end
  end

  def validate_optional(issues, path, artifact, field \\ "authority_context") do
    evaluation_field = "authority_context_evaluation"
    context_present? = Map.has_key?(artifact, field)
    evaluation_present? = Map.has_key?(artifact, evaluation_field)
    context = Map.get(artifact, field)
    evaluation = Map.get(artifact, evaluation_field)

    cond do
      not context_present? and not evaluation_present? ->
        issues

      context_present? and not evaluation_present? ->
        [
          error(
            "#{path}.#{evaluation_field}",
            "is required whenever authority_context is present"
          )
          | validate_context_value(issues, "#{path}.#{field}", context)
        ]

      true ->
        validate_context_evaluation(issues, path, context, evaluation)
    end
  end

  def validate_policy_boundary(issues, path, artifact) do
    issues
    |> validate_optional(path, artifact)
    |> validate_overall_eligibility(path, artifact, Map.get(artifact, "classification"))
  end

  def validate_recommendation_boundary(issues, path, artifact) do
    issues
    |> validate_optional(path, artifact)
    |> validate_overall_eligibility(path, artifact, Map.get(artifact, "approval_status"))
  end

  def validate_campaign_boundary(issues, path, artifact) do
    classification = get_in(artifact, ["recommendation", "approval_status"])

    issues
    |> validate_optional(path, artifact)
    |> validate_overall_eligibility(path, artifact, classification)
  end

  def validate_operator_review_boundary(issues, path, artifact) do
    strategy_rows = operator_review_strategy_targets(artifact, path)
    classification = artifact["approval_status"] || first_approval_status(strategy_rows)

    issues
    |> validate_optional(path, artifact)
    |> validate_overall_eligibility(path, artifact, classification)
    |> validate_container_propagation(artifact, strategy_rows, @propagation_fields)
  end

  def validate_cadence_import_manifest_boundary(issues, path, manifest) do
    branch_targets = cadence_branch_targets(manifest, path)
    other_targets = cadence_authority_targets(manifest, path)
    classification = first_selected_approval_status(branch_targets)

    issues
    |> validate_optional(path, manifest)
    |> validate_overall_eligibility(path, manifest, classification)
    |> validate_container_propagation(manifest, other_targets, @propagation_fields)
    |> validate_branch_manifest_targets(manifest, branch_targets)
    |> validate_import_manifest_ready_count(path, manifest)
  end

  def validate_cadence_import_row_boundary(issues, path, row) do
    issues
    |> validate_optional(path, row)
    |> validate_overall_eligibility(path, row, Map.get(row, "approval_status"))
    |> validate_import_row_readiness(path, row)
  end

  def validate_strategy_propagation(issues, artifact) when is_map(artifact) do
    if contains_authority_evidence?(artifact) do
      targets =
        [
          {"$.recommendation", Map.get(artifact, "recommendation")},
          {"$.operator_review_package", Map.get(artifact, "operator_review_package")},
          {"$.cadence_import_manifest", Map.get(artifact, "cadence_import_manifest")}
        ] ++ review_targets(artifact) ++ manifest_authority_targets(artifact)

      targets
      |> Enum.reduce(issues, fn {target_path, target}, acc ->
        validate_propagation_target(acc, artifact, target_path, target, @propagation_fields)
      end)
      |> then(fn acc ->
        Enum.reduce(branch_decision_targets(artifact), acc, fn {target_path, target},
                                                               nested_acc ->
          validate_propagation_target(
            nested_acc,
            artifact,
            target_path,
            target,
            @evidence_propagation_fields
          )
        end)
      end)
      |> then(fn acc ->
        validate_branch_manifest_targets(acc, artifact, manifest_branch_targets(artifact))
      end)
    else
      issues
    end
  end

  def validate_strategy_propagation(issues, _artifact), do: issues

  def json_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => OrbitalDynamics.AuthorityContext.required_fields(),
      "properties" => %{
        "schema_contract" => %{"const" => "authority_context.v1", "type" => "string"},
        "authority_context_id" => %{"type" => "string", "pattern" => @identity_pattern},
        "authority_source" => %{"type" => "string", "minLength" => 1},
        "source_revision" => %{"type" => "string", "minLength" => 1},
        "effective_from" => %{"type" => "string", "format" => "date-time"},
        "valid_until" => %{"type" => "string", "format" => "date-time"},
        "evaluation_time" => %{"type" => "string", "format" => "date-time"}
      }
    }
  end

  def evaluation_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "mode",
        "eligibility_status",
        "outcome",
        "reason_code",
        "reason",
        "provenance"
      ],
      "properties" => %{
        "mode" => %{
          "type" => "string",
          "enum" => ["explicit", "missing", "invalid"]
        },
        "eligibility_status" => %{
          "type" => "string",
          "enum" => ["eligible", "non_eligible"]
        },
        "outcome" => %{
          "type" => "string",
          "enum" => ["policy_evaluation_allowed", "blocked_by_policy"]
        },
        "reason_code" => %{
          "type" => "string",
          "enum" => [
            "authority_context_valid",
            "ambiguous_authority_context_options",
            "missing_authority_context_mode",
            "invalid_authority_context_mode",
            "missing_authority_context",
            "malformed_authority_context",
            "authority_context_not_yet_effective",
            "stale_authority_context"
          ]
        },
        "reason" => %{"type" => "string", "minLength" => 1},
        "authority_context_id" => %{"type" => "string", "pattern" => @identity_pattern},
        "authority_source" => %{"type" => "string", "minLength" => 1},
        "source_revision" => %{"type" => "string", "minLength" => 1},
        "evaluation_time" => %{"type" => "string", "format" => "date-time"},
        "provenance" => %{
          "type" => "object",
          "additionalProperties" => true,
          "required" => [
            "input_source",
            "validation",
            "operation",
            "authority_context_mode_supplied",
            "authority_context_supplied"
          ],
          "properties" => %{
            "input_source" => %{"const" => "caller_supplied", "type" => "string"},
            "validation" => %{
              "const" => "deterministic_no_wall_clock",
              "type" => "string"
            },
            "operation" => %{
              "type" => "string",
              "enum" => ["constructor", "policy_boundary"]
            },
            "authority_context_mode_supplied" => %{"type" => "boolean"},
            "authority_context_supplied" => %{"type" => "boolean"},
            "provided_authority_context_mode" => %{"type" => "object"},
            "provided_authority_context" => %{"type" => "object"}
          }
        },
        "validation_errors" => %{"type" => "array", "items" => %{"type" => "object"}}
      }
    }
  end

  def property(field), do: json_schema() |> Map.fetch!("properties") |> Map.fetch!(field)

  defp validate_context_evaluation(issues, path, context, evaluation) do
    case OrbitalDynamics.AuthorityContext.validate_evaluation(context, evaluation) do
      {:ok, _result} ->
        issues

      {:error, validation_errors} ->
        Enum.reduce(validation_errors, issues, fn validation_error, acc ->
          relative_path =
            validation_error["path"]
            |> to_string()
            |> String.trim_leading("$")

          [error(path <> relative_path, validation_error["reason"]) | acc]
        end)
    end
  end

  defp validate_context_value(issues, path, %{} = context), do: validate(issues, path, context)

  defp validate_context_value(issues, path, _context),
    do: [error(path, "must be an object") | issues]

  defp validate_overall_eligibility(issues, path, artifact, classification) do
    evaluation = Map.get(artifact, "authority_context_evaluation")
    actual = Map.get(artifact, "eligibility_status")

    cond do
      not is_map(evaluation) ->
        issues

      evaluation["outcome"] == "blocked_by_policy" and actual != "non_eligible" ->
        [
          error(
            path <> ".eligibility_status",
            "must be non_eligible for failed authority evidence"
          )
          | issues
        ]

      classification == "blocked_by_policy" and actual != "non_eligible" ->
        [
          error(
            path <> ".eligibility_status",
            "must preserve substantive blocked_by_policy eligibility"
          )
          | issues
        ]

      classification in ["auto_approvable", "operator_review_required"] and
        evaluation["outcome"] == "policy_evaluation_allowed" and actual != "eligible" ->
        [
          error(
            path <> ".eligibility_status",
            "must be eligible when policy and authority evidence are eligible"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp validate_import_row_readiness(issues, path, row) do
    if authority_non_eligible?(row) and row["import_status"] == "ready_for_import" do
      [
        error(
          path <> ".import_status",
          "must not be ready_for_import when policy or authority eligibility is non_eligible"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_import_manifest_ready_count(issues, path, manifest) do
    rows = if is_list(manifest["rows"]), do: manifest["rows"], else: []

    eligible_ready_count =
      Enum.count(rows, fn row ->
        is_map(row) and row["import_status"] == "ready_for_import" and
          not authority_non_eligible?(row)
      end)

    if contains_authority_evidence?(manifest) and manifest["ready_count"] != eligible_ready_count do
      [
        error(
          path <> ".ready_count",
          "must count only authority-eligible ready_for_import rows"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp authority_non_eligible?(artifact) do
    evaluation = Map.get(artifact, "authority_context_evaluation")

    is_map(evaluation) and
      (evaluation["outcome"] == "blocked_by_policy" or
         artifact["eligibility_status"] == "non_eligible" or
         artifact["approval_status"] == "blocked_by_policy")
  end

  defp branch_decision_targets(%{"branches" => branches}) when is_list(branches) do
    branches
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"policy_decision" => decision}, index} ->
        [{"$.branches[#{index}].policy_decision", decision}]

      {_branch, _index} ->
        []
    end)
  end

  defp branch_decision_targets(_artifact), do: []

  defp review_targets(artifact) do
    artifact
    |> nested_rows("operator_review_package")
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"review_type" => "strategy_recommendation"} = row, index} ->
        [{"$.operator_review_package.rows[#{index}]", row}]

      {_row, _index} ->
        []
    end)
  end

  defp manifest_branch_targets(artifact) do
    artifact
    |> nested_rows("cadence_import_manifest")
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"source_review_type" => "strategy_branch_comparison"} = row, index} ->
        [{"$.cadence_import_manifest.rows[#{index}]", row}]

      {_row, _index} ->
        []
    end)
  end

  defp manifest_authority_targets(artifact) do
    artifact
    |> nested_rows("cadence_import_manifest")
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"source_review_type" => "strategy_branch_comparison"}, _index} ->
        []

      {%{} = row, index} ->
        if contains_authority_evidence?(row),
          do: [{"$.cadence_import_manifest.rows[#{index}]", row}],
          else: []

      {_row, _index} ->
        []
    end)
  end

  defp operator_review_strategy_targets(artifact, path) do
    artifact
    |> Map.get("rows", [])
    |> indexed_rows(path <> ".rows", "review_type", "strategy_recommendation")
  end

  defp cadence_branch_targets(manifest, path) do
    manifest
    |> Map.get("rows", [])
    |> indexed_rows(path <> ".rows", "source_review_type", "strategy_branch_comparison")
  end

  defp cadence_authority_targets(manifest, path) do
    branch_paths =
      cadence_branch_targets(manifest, path) |> MapSet.new(fn {row_path, _row} -> row_path end)

    manifest
    |> Map.get("rows", [])
    |> case do
      rows when is_list(rows) -> rows
      _rows -> []
    end
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{} = row, index} ->
        row_path = "#{path}.rows[#{index}]"

        if not MapSet.member?(branch_paths, row_path) and contains_authority_evidence?(row),
          do: [{row_path, row}],
          else: []

      {_row, _index} ->
        []
    end)
  end

  defp indexed_rows(rows, path, field, value) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{} = row, index} ->
        if row[field] == value, do: [{"#{path}[#{index}]", row}], else: []

      {_row, _index} ->
        []
    end)
  end

  defp indexed_rows(_rows, _path, _field, _value), do: []

  defp first_approval_status(targets) do
    case targets do
      [{_path, row} | _targets] -> row["approval_status"]
      [] -> nil
    end
  end

  defp first_selected_approval_status(targets) do
    targets
    |> Enum.find(fn {_path, row} ->
      row["selected"] == true or row["import_action"] == "import_strategy_recommendation"
    end)
    |> case do
      {_path, row} -> row["approval_status"]
      nil -> nil
    end
  end

  defp nested_rows(artifact, field) do
    case Map.get(artifact, field) do
      %{"rows" => rows} when is_list(rows) -> rows
      _value -> []
    end
  end

  defp validate_propagation_target(issues, _source, _path, target, _fields)
       when not is_map(target),
       do: issues

  defp validate_propagation_target(issues, source, path, target, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      if Map.get(target, field) == Map.get(source, field) do
        acc
      else
        [error("#{path}.#{field}", "must match the enclosing CampaignStrategy #{field}") | acc]
      end
    end)
  end

  defp validate_container_propagation(issues, source, targets, fields) do
    if contains_authority_evidence?(source) or
         Enum.any?(targets, fn {_path, target} -> contains_authority_evidence?(target) end) do
      Enum.reduce(targets, issues, fn {target_path, target}, acc ->
        validate_propagation_target(acc, source, target_path, target, fields)
      end)
    else
      issues
    end
  end

  defp validate_branch_manifest_targets(issues, source, targets) do
    if contains_authority_evidence?(source) or
         Enum.any?(targets, fn {_path, target} -> contains_authority_evidence?(target) end) do
      Enum.reduce(targets, issues, fn {target_path, target}, acc ->
        expected_eligibility =
          if target["approval_status"] == "blocked_by_policy",
            do: "non_eligible",
            else: source["eligibility_status"]

        acc
        |> validate_propagation_target(
          source,
          target_path,
          target,
          @evidence_propagation_fields
        )
        |> validate_expected_branch_eligibility(target_path, target, expected_eligibility)
      end)
    else
      issues
    end
  end

  defp validate_expected_branch_eligibility(issues, path, target, expected) do
    if target["eligibility_status"] == expected do
      issues
    else
      [
        error(
          path <> ".eligibility_status",
          "must preserve branch-specific substantive and authority eligibility"
        )
        | issues
      ]
    end
  end

  defp contains_authority_evidence?(%{} = value) do
    Map.has_key?(value, "authority_context") or
      Map.has_key?(value, "authority_context_evaluation") or
      Enum.any?(value, fn {_key, nested} -> contains_authority_evidence?(nested) end)
  end

  defp contains_authority_evidence?(values) when is_list(values),
    do: Enum.any?(values, &contains_authority_evidence?/1)

  defp contains_authority_evidence?(_value), do: false
end
