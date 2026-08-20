defmodule OrbitalDynamics.Schema.AuthorityContextContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @identity_pattern "^authority_context:[0-9a-f]{64}$"
  @utc_datetime_pattern "Z$"
  @propagation_fields ~w(eligibility_status authority_context authority_context_evaluation)
  @evidence_propagation_fields ~w(authority_context authority_context_evaluation)
  @retained_recommendation_fields ~w(approval_status eligibility_status authority_context authority_context_evaluation)
  @strategy_recommendation_source_required_fields ~w(
    schema_contract
    recommended_branch_id
    approval_status
    reason
    ranked_branch_ids
    tradeoffs
    explanation
    risks_remaining
    requires_approval
  )
  @branch_comparison_source_required_fields ~w(
    id
    rank
    branch_id
    score
    score_delta_from_recommended
    selected
    approval_status
    risk_count
    approval_requirement_count
    score_terms
  )

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
        issues
        |> validate_failed_context_absence(path, field, context_present?, evaluation)
        |> validate_context_evaluation(path, context, evaluation)
    end
  end

  def validate_policy_boundary(issues, path, artifact) do
    issues
    |> validate_optional(path, artifact)
    |> validate_nested_authority_root(path, artifact)
    |> validate_overall_eligibility(path, artifact, Map.get(artifact, "classification"))
  end

  def validate_recommendation_boundary(issues, path, artifact) do
    issues
    |> validate_optional(path, artifact)
    |> validate_nested_authority_root(path, artifact)
    |> validate_overall_eligibility(path, artifact, Map.get(artifact, "approval_status"))
  end

  def validate_campaign_boundary(issues, path, artifact) do
    classification = get_in(artifact, ["recommendation", "approval_status"])

    issues
    |> validate_optional(path, artifact)
    |> validate_nested_authority_root(path, artifact)
    |> validate_overall_eligibility(path, artifact, classification)
  end

  def validate_operator_review_boundary(issues, path, artifact) do
    strategy_rows = operator_review_strategy_targets(artifact, path)
    classification = first_retained_approval_status(strategy_rows) || artifact["approval_status"]

    issues
    |> validate_optional(path, artifact)
    |> validate_nested_authority_root(path, artifact)
    |> validate_overall_eligibility(path, artifact, classification)
    |> validate_container_propagation(artifact, strategy_rows, @propagation_fields)
  end

  def validate_cadence_import_manifest_boundary(issues, path, manifest) do
    branch_targets = cadence_branch_targets(manifest, path)
    other_targets = cadence_authority_targets(manifest, path)
    classification = first_selected_approval_status(branch_targets)

    issues
    |> validate_optional(path, manifest)
    |> validate_nested_authority_root(path, manifest)
    |> validate_overall_eligibility(path, manifest, classification)
    |> validate_container_propagation(manifest, other_targets, @propagation_fields)
    |> validate_branch_manifest_targets(manifest, branch_targets)
    |> validate_import_manifest_ready_count(path, manifest)
  end

  def validate_cadence_import_row_boundary(issues, path, row) do
    classification = retained_classification(row) || Map.get(row, "approval_status")

    issues
    |> validate_optional(path, row)
    |> validate_retained_source_shapes(path, row)
    |> validate_nested_authority_root(path, row)
    |> validate_overall_eligibility(path, row, classification)
    |> validate_required_cadence_strategy_sources(path, row)
    |> validate_retained_recommendation(path, row)
    |> validate_retained_branch_decision(path, row)
    |> validate_import_row_readiness(path, row)
    |> validate_retained_import_status(path, row)
  end

  def validate_operator_review_row_boundary(issues, path, row) do
    classification = retained_classification(row) || Map.get(row, "approval_status")

    issues
    |> validate_optional(path, row)
    |> validate_retained_source_shapes(path, row)
    |> validate_nested_authority_root(path, row)
    |> validate_overall_eligibility(path, row, classification)
    |> validate_required_review_strategy_source(path, row)
    |> validate_retained_recommendation(path, row)
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
        "effective_from" => utc_datetime_schema(),
        "valid_until" => utc_datetime_schema(),
        "evaluation_time" => utc_datetime_schema()
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
            "invalid_authority_context_options",
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
        "evaluation_time" => utc_datetime_schema(),
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
            "provided_authority_context" => %{"type" => "object"},
            "provided_options" => %{"type" => "object"}
          }
        },
        "validation_errors" => %{"type" => "array", "items" => %{"type" => "object"}}
      }
    }
  end

  def property(field), do: json_schema() |> Map.fetch!("properties") |> Map.fetch!(field)

  defp utc_datetime_schema do
    %{"type" => "string", "format" => "date-time", "pattern" => @utc_datetime_pattern}
  end

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

  defp validate_failed_context_absence(
         issues,
         path,
         field,
         true,
         %{"outcome" => "blocked_by_policy"}
       ) do
    [error("#{path}.#{field}", "must be absent for a failed authority evaluation") | issues]
  end

  defp validate_failed_context_absence(
         issues,
         _path,
         _field,
         _context_present?,
         _evaluation
       ),
       do: issues

  defp validate_retained_source_shapes(issues, path, row) do
    issues
    |> validate_optional_retained_map(path, row, "source_branch_comparison")
    |> validate_optional_retained_map(path, row, "source_recommendation")
    |> validate_source_review_row_shape(path, row)
  end

  defp validate_optional_retained_map(issues, path, row, field) do
    if Map.has_key?(row, field) and not is_map(row[field]) do
      [error("#{path}.#{field}", "must be an object when present") | issues]
    else
      issues
    end
  end

  defp validate_source_review_row_shape(issues, path, row) do
    case Map.fetch(row, "source_review_row") do
      :error ->
        issues

      {:ok, %{} = source_review_row} ->
        validate_optional_retained_map(
          issues,
          path <> ".source_review_row",
          source_review_row,
          "source_recommendation"
        )

      {:ok, _source_review_row} ->
        [error(path <> ".source_review_row", "must be an object when present") | issues]
    end
  end

  defp validate_required_review_strategy_source(issues, path, row) do
    if authority_bearing_strategy_row?(row) and
         row["review_type"] == "strategy_recommendation" and
         not authoritative_recommendation?(retained_recommendation(row)) do
      [
        error(
          path <> ".source_recommendation",
          "is required as authoritative retained evidence for an authority-bearing strategy row"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_required_cadence_strategy_sources(issues, path, row) do
    if authority_bearing_strategy_row?(row) and cadence_strategy_row?(row) do
      issues
      |> require_authoritative_recommendation(path, row)
      |> require_branch_comparison_source(path, row)
    else
      issues
    end
  end

  defp require_authoritative_recommendation(issues, path, row) do
    if authoritative_recommendation?(retained_recommendation(row)) do
      issues
    else
      [
        error(
          path <> ".source_recommendation",
          "is required as authoritative retained evidence for an authority-bearing strategy row"
        )
        | issues
      ]
    end
  end

  defp require_branch_comparison_source(issues, path, row) do
    source = retained_branch_comparison(row)

    if complete_branch_comparison_source?(source) do
      issues
    else
      [
        error(
          path <> ".source_branch_comparison",
          "is required as authoritative retained evidence for an authority-bearing strategy row"
        )
        | issues
      ]
    end
  end

  defp authoritative_recommendation?(recommendation) do
    complete_source_fields?(recommendation, @strategy_recommendation_source_required_fields) and
      recommendation["schema_contract"] == "strategy_recommendation.v1" and
      is_binary(recommendation["approval_status"]) and
      is_binary(recommendation["eligibility_status"]) and
      is_map(recommendation["authority_context_evaluation"])
  end

  defp complete_branch_comparison_source?(source) do
    complete_source_fields?(source, @branch_comparison_source_required_fields) and
      is_binary(source["id"]) and is_binary(source["branch_id"]) and
      is_binary(source["approval_status"])
  end

  defp complete_source_fields?(source, fields) when is_map(source) do
    map_size(source) > 0 and Enum.all?(fields, &Map.has_key?(source, &1))
  end

  defp authority_bearing_strategy_row?(row) do
    Map.has_key?(row, "eligibility_status") or
      Map.has_key?(row, "authority_context") or
      Map.has_key?(row, "authority_context_evaluation")
  end

  defp cadence_strategy_row?(row) do
    row["source_review_type"] == "strategy_branch_comparison" or
      row["import_action"] in [
        "import_strategy_recommendation",
        "review_strategy_branch_alternative"
      ]
  end

  defp validate_nested_authority_root(issues, path, artifact) do
    if contains_nested_authority_evidence?(artifact) do
      required_fields =
        ["eligibility_status", "authority_context_evaluation"] ++
          if nested_authority_context_present?(artifact), do: ["authority_context"], else: []

      Enum.reduce(required_fields, issues, fn field, acc ->
        if Map.has_key?(artifact, field) do
          acc
        else
          [
            error(
              "#{path}.#{field}",
              "must preserve recursively retained authority evidence at this boundary"
            )
            | acc
          ]
        end
      end)
    else
      issues
    end
  end

  defp validate_overall_eligibility(issues, path, artifact, classification) do
    evaluation = Map.get(artifact, "authority_context_evaluation")
    actual = Map.get(artifact, "eligibility_status")

    issues
    |> validate_eligibility_evidence_correlation(path, artifact, evaluation)
    |> validate_substantive_eligibility(path, artifact, classification, actual)
    |> validate_authority_eligibility(path, evaluation, classification, actual)
  end

  defp validate_eligibility_evidence_correlation(issues, path, artifact, evaluation) do
    if Map.has_key?(artifact, "eligibility_status") and not is_map(evaluation) do
      [
        error(
          path <> ".eligibility_status",
          "requires a correlated authority_context_evaluation"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_substantive_eligibility(
         issues,
         path,
         artifact,
         "blocked_by_policy",
         actual
       ) do
    if Map.has_key?(artifact, "eligibility_status") and actual != "non_eligible" do
      [
        error(
          path <> ".eligibility_status",
          "must preserve substantive blocked_by_policy eligibility"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_substantive_eligibility(
         issues,
         _path,
         _artifact,
         _classification,
         _actual
       ),
       do: issues

  defp validate_authority_eligibility(issues, _path, evaluation, _classification, _actual)
       when not is_map(evaluation),
       do: issues

  defp validate_authority_eligibility(issues, path, evaluation, classification, actual) do
    cond do
      evaluation["outcome"] == "blocked_by_policy" and actual != "non_eligible" ->
        [
          error(
            path <> ".eligibility_status",
            "must be non_eligible for failed authority evidence"
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

    if manifest["ready_count"] != eligible_ready_count do
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
    recommendation = retained_recommendation(artifact)

    evaluation =
      Map.get(recommendation, "authority_context_evaluation") ||
        Map.get(artifact, "authority_context_evaluation")

    eligibility = Map.get(recommendation, "eligibility_status") || artifact["eligibility_status"]
    classification = retained_classification(artifact) || artifact["approval_status"]

    (is_map(evaluation) and evaluation["outcome"] == "blocked_by_policy") or
      eligibility == "non_eligible" or classification == "blocked_by_policy" or
      retained_blocked_by_policy?(artifact) or retained_failed_authority?(artifact)
  end

  defp validate_retained_recommendation(issues, path, row) do
    recommendation = retained_recommendation(row)

    if map_size(recommendation) > 0 do
      fields =
        if map_size(retained_branch_comparison(row)) > 0,
          do: @evidence_propagation_fields,
          else: @retained_recommendation_fields

      issues
      |> validate_complete_recommendation_source(path, row, recommendation)
      |> validate_retained_source_boundary(
        path <> ".source_recommendation",
        recommendation,
        recommendation["approval_status"]
      )
      |> validate_required_source_fields(
        path,
        row,
        recommendation,
        fields,
        "source_recommendation"
      )
    else
      issues
    end
  end

  defp validate_retained_branch_decision(issues, path, row) do
    source = retained_branch_comparison(row)

    if map_size(source) > 0 do
      classification = retained_source_classification(source)

      issues =
        issues
        |> validate_complete_branch_comparison_source(path, row, source)
        |> validate_retained_source_boundary(
          path <> ".source_branch_comparison",
          source,
          classification
        )

      if is_nil(classification) do
        issues
      else
        validate_required_source_fields(
          issues,
          path,
          row,
          %{"approval_status" => classification},
          ["approval_status"],
          "source_branch_comparison"
        )
      end
    else
      issues
    end
  end

  defp validate_complete_recommendation_source(issues, path, row, recommendation) do
    if authority_strategy_source_row?(row) do
      OrbitalDynamics.Schema.CampaignArtifactValidation.validate_recommendation_artifact(
        issues,
        path <> ".source_recommendation",
        recommendation
      )
    else
      issues
    end
  end

  defp validate_complete_branch_comparison_source(issues, path, row, source) do
    if authority_bearing_strategy_row?(row) and cadence_strategy_row?(row) do
      OrbitalDynamics.Schema.BranchComparisonReportContracts.validate_row(
        issues,
        path <> ".source_branch_comparison",
        source
      )
    else
      issues
    end
  end

  defp authority_strategy_source_row?(row) do
    authority_bearing_strategy_row?(row) and
      (row["review_type"] == "strategy_recommendation" or cadence_strategy_row?(row))
  end

  defp validate_retained_source_boundary(issues, path, source, classification) do
    issues
    |> validate_optional(path, source)
    |> validate_nested_authority_root(path, source)
    |> validate_overall_eligibility(path, source, classification)
  end

  defp validate_retained_import_status(issues, path, row) do
    case expected_retained_import_status(row) do
      nil ->
        issues

      expected ->
        if row["import_status"] == expected do
          issues
        else
          [
            error(
              path <> ".import_status",
              "must equal #{expected} from retained strategy source evidence"
            )
            | issues
          ]
        end
    end
  end

  defp expected_retained_import_status(row) do
    source = retained_branch_comparison(row)

    if authority_bearing_strategy_row?(row) and
         row["source_review_type"] == "strategy_branch_comparison" and
         map_size(source) > 0 do
      selected? = source["selected"] == true
      approval_status = retained_classification(row)
      eligibility_status = retained_eligibility(row)

      cond do
        not selected? ->
          "not_applicable"

        approval_status in ["auto_approvable", "not_required"] and
            eligibility_status == "eligible" ->
          "ready_for_import"

        true ->
          "review_required_before_import"
      end
    end
  end

  defp validate_required_source_fields(issues, path, target, source, fields, source_name) do
    Enum.reduce(fields, issues, fn field, acc ->
      if Map.has_key?(source, field) do
        cond do
          not Map.has_key?(target, field) ->
            [error("#{path}.#{field}", "must preserve #{source_name}.#{field}") | acc]

          target[field] != source[field] ->
            [error("#{path}.#{field}", "must match #{source_name}.#{field}") | acc]

          true ->
            acc
        end
      else
        acc
      end
    end)
  end

  defp retained_classification(row) do
    case retained_branch_comparison(row) do
      source when map_size(source) > 0 -> retained_source_classification(source)
      _source -> retained_source_classification(retained_recommendation(row))
    end
  end

  defp retained_source_classification(source) do
    source["approval_status"] || source["classification"] ||
      if(nested_blocked_by_policy?(source), do: "blocked_by_policy")
  end

  defp retained_eligibility(row) do
    recommendation = retained_recommendation(row)

    cond do
      retained_classification(row) == "blocked_by_policy" -> "non_eligible"
      retained_failed_authority?(row) -> "non_eligible"
      is_binary(recommendation["eligibility_status"]) -> recommendation["eligibility_status"]
      true -> nil
    end
  end

  defp retained_blocked_by_policy?(row) do
    nested_blocked_by_policy?(retained_branch_comparison(row)) or
      nested_blocked_by_policy?(retained_recommendation(row))
  end

  defp retained_failed_authority?(row) do
    failed_authority_evidence?(retained_branch_comparison(row)) or
      failed_authority_evidence?(retained_recommendation(row))
  end

  defp retained_recommendation(%{"source_recommendation" => %{} = recommendation}),
    do: recommendation

  defp retained_recommendation(%{
         "source_review_row" => %{"source_recommendation" => %{} = recommendation}
       }),
       do: recommendation

  defp retained_recommendation(_row), do: %{}

  defp retained_branch_comparison(%{"source_branch_comparison" => %{} = source}), do: source
  defp retained_branch_comparison(_row), do: %{}

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

  defp first_retained_approval_status(targets) do
    case targets do
      [{_path, row} | _targets] -> retained_classification(row) || row["approval_status"]
      [] -> nil
    end
  end

  defp first_selected_approval_status(targets) do
    targets
    |> Enum.find(fn {_path, row} ->
      retained_branch_comparison(row)["selected"] == true or
        row["import_action"] == "import_strategy_recommendation"
    end)
    |> case do
      {_path, row} -> retained_classification(row) || row["approval_status"]
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
        expected_eligibility = retained_eligibility(target) || source["eligibility_status"]

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

  defp contains_authority_evidence?([]), do: false

  defp contains_authority_evidence?([head | tail]),
    do: contains_authority_evidence?(head) or contains_authority_evidence?(tail)

  defp contains_authority_evidence?(_value), do: false

  defp contains_nested_authority_evidence?(%{} = value) do
    Enum.any?(value, fn
      {key, _nested} when key in @evidence_propagation_fields -> false
      {_key, nested} -> contains_authority_evidence?(nested)
    end)
  end

  defp contains_nested_authority_evidence?(_value), do: false

  defp nested_authority_context_present?(%{} = value) do
    Enum.any?(value, fn
      {key, _nested} when key in @evidence_propagation_fields -> false
      {_key, nested} -> authority_context_present?(nested)
    end)
  end

  defp authority_context_present?(%{} = value) do
    Map.has_key?(value, "authority_context") or
      Enum.any?(value, fn {_key, nested} -> authority_context_present?(nested) end)
  end

  defp authority_context_present?([]), do: false

  defp authority_context_present?([head | tail]),
    do: authority_context_present?(head) or authority_context_present?(tail)

  defp authority_context_present?(_value), do: false

  defp failed_authority_evidence?(%{} = value) do
    get_in(value, ["authority_context_evaluation", "outcome"]) == "blocked_by_policy" or
      Enum.any?(value, fn {_key, nested} -> failed_authority_evidence?(nested) end)
  end

  defp failed_authority_evidence?([]), do: false

  defp failed_authority_evidence?([head | tail]),
    do: failed_authority_evidence?(head) or failed_authority_evidence?(tail)

  defp failed_authority_evidence?(_value), do: false

  defp nested_blocked_by_policy?(%{} = value) do
    value["classification"] == "blocked_by_policy" or
      value["approval_status"] == "blocked_by_policy" or
      Enum.any?(value, fn {_key, nested} -> nested_blocked_by_policy?(nested) end)
  end

  defp nested_blocked_by_policy?([]), do: false

  defp nested_blocked_by_policy?([head | tail]),
    do: nested_blocked_by_policy?(head) or nested_blocked_by_policy?(tail)

  defp nested_blocked_by_policy?(_value), do: false
end
