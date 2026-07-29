defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CadenceImportValidation,
    DecisionSupportValidation,
    StableIdValidation
  }

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_type: 5,
      require_fields: 4
    ]

  @provenance_path "$.operational_feedback_provenance"
  @provenance_model "deterministic_merge_explicit_overrides_mission_state_overrides_prior_plan"
  @provenance_fields ~w(
    model
    merge_order
    input_keys
    effective_sources
    overridden_sources
    source_count
    sources
    explicit_request_override
  )
  @operational_feedback_fields ~w(
    contact_success_rate
    observation_success_rate
    image_quality_score
    image_quality_status
    image_quality_source
    cloud_cover_fraction
    blur_score
    maneuver_success_rate
    maneuver_execution_uncertainty
    command_success_rate
    station_throughput_factor
    downlink_demand_mb
    downlink_demand_sources
    downlink_demand_context
    target_priority_overrides
    resource_margin_overrides
    resource_availability_overrides
  )
  @source_provenance_fields ~w(
    source_plan_id
    source_planner
    source_plan_generated_at
    source_provenance
  )

  def validate(issues, artifact) do
    issues
    |> StableIdValidation.validate_optional_stable_ids("$", artifact, ["source_repair_id"])
    |> validate_branch_metadata(artifact)
    |> validate_ranked_branch_eligibility(artifact)
    |> validate_source_provenance(artifact)
    |> validate_optional_score_term_report(Map.get(artifact, "score_term_report"))
    |> validate_optional_objective_tradeoff_report(Map.get(artifact, "objective_tradeoff_report"))
    |> validate_optional_pareto_frontier_report(Map.get(artifact, "pareto_frontier_report"))
    |> validate_optional_cadence_import_manifest(Map.get(artifact, "cadence_import_manifest"))
    |> validate_optional_operational_feedback_provenance(artifact)
  end

  defp validate_branch_metadata(
         issues,
         %{"branches" => branches, "strategy_metadata" => %{} = metadata}
       )
       when is_list(branches) do
    issues =
      expect_equal(
        issues,
        "$.strategy_metadata",
        metadata,
        "branch_count",
        length(branches)
      )

    case Enum.filter(branches, &(is_map(&1) and Map.get(&1, "branch_id") == "baseline")) do
      [_baseline] ->
        expect_equal(
          issues,
          "$.strategy_metadata",
          metadata,
          "baseline_branch_id",
          "baseline"
        )

      _missing_or_ambiguous_baseline ->
        issues
    end
  end

  defp validate_branch_metadata(issues, _artifact), do: issues

  defp validate_ranked_branch_eligibility(
         issues,
         %{
           "branches" => branches,
           "recommendation" => %{"ranked_branch_ids" => ranked_branch_ids}
         }
       )
       when is_list(branches) and is_list(ranked_branch_ids) do
    if Enum.all?(branches, &valid_branch_rank_input?/1) and
         Enum.all?(ranked_branch_ids, &is_binary/1) do
      branch_ids = Enum.map(branches, &Map.fetch!(&1, "branch_id"))

      selectable_branch_ids =
        branches
        |> Enum.reject(&(&1["approval_status"] == "blocked_by_policy"))
        |> Enum.map(&Map.fetch!(&1, "branch_id"))

      expected_branch_ids =
        if selectable_branch_ids == [], do: branch_ids, else: selectable_branch_ids

      if ranked_branch_ids == expected_branch_ids do
        issues
      else
        [
          error(
            "$.recommendation.ranked_branch_ids",
            "must equal selectable branch IDs in enclosing branch order, falling back to all branch IDs when every branch is blocked"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_ranked_branch_eligibility(issues, _artifact), do: issues

  defp valid_branch_rank_input?(%{"branch_id" => id, "approval_status" => status}),
    do: is_binary(id) and is_binary(status)

  defp valid_branch_rank_input?(_branch), do: false

  defp validate_source_provenance(issues, artifact) do
    provenance = Map.get(artifact, "provenance")

    issues
    |> validate_optional_copy(
      "$.provenance.source_plan_id",
      provenance,
      "source_plan_id",
      Map.get(artifact, "source_plan_id"),
      "must match enclosing CampaignStrategy source_plan_id"
    )
    |> validate_operator_review_provenance(
      provenance,
      get_in(artifact, ["operator_review_package", "provenance"])
    )
    |> validate_optional_copy(
      "$.cadence_import_manifest.provenance.source_plan_id",
      get_in(artifact, ["cadence_import_manifest", "provenance"]),
      "source_plan_id",
      Map.get(artifact, "source_plan_id"),
      "must match enclosing CampaignStrategy source_plan_id"
    )
  end

  defp validate_operator_review_provenance(
         issues,
         %{} = provenance,
         %{} = review_provenance
       ) do
    Enum.reduce(@source_provenance_fields, issues, fn field, acc ->
      if Map.has_key?(provenance, field) and Map.has_key?(review_provenance, field) do
        validate_optional_copy(
          acc,
          "$.operator_review_package.provenance.#{field}",
          review_provenance,
          field,
          Map.get(provenance, field),
          "must match enclosing CampaignStrategy provenance.#{field}"
        )
      else
        acc
      end
    end)
  end

  defp validate_operator_review_provenance(issues, _provenance, _review_provenance),
    do: issues

  defp validate_optional_copy(issues, path, %{} = container, field, expected, message) do
    if Map.has_key?(container, field) and Map.get(container, field) != expected,
      do: [error(path, message) | issues],
      else: issues
  end

  defp validate_optional_copy(issues, _path, _container, _field, _expected, _message),
    do: issues

  defp validate_optional_score_term_report(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_score_term_report(issues, %{} = report) do
    DecisionSupportValidation.validate_score_term_report(
      issues,
      "$.score_term_report",
      report
    )
  end

  defp validate_optional_score_term_report(issues, _report),
    do: [error("$.score_term_report", "must be an object") | issues]

  defp validate_optional_objective_tradeoff_report(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_objective_tradeoff_report(issues, %{} = report) do
    DecisionSupportValidation.validate_objective_tradeoff_report(
      issues,
      "$.objective_tradeoff_report",
      report
    )
  end

  defp validate_optional_objective_tradeoff_report(issues, _report),
    do: [error("$.objective_tradeoff_report", "must be an object") | issues]

  defp validate_optional_pareto_frontier_report(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_pareto_frontier_report(issues, %{} = report) do
    DecisionSupportValidation.validate_pareto_frontier_report(
      issues,
      "$.pareto_frontier_report",
      report
    )
  end

  defp validate_optional_pareto_frontier_report(issues, _report),
    do: [error("$.pareto_frontier_report", "must be an object") | issues]

  defp validate_optional_cadence_import_manifest(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_cadence_import_manifest(issues, %{} = manifest) do
    CadenceImportValidation.validate_manifest_artifact(
      issues,
      "$.cadence_import_manifest",
      manifest
    )
  end

  defp validate_optional_cadence_import_manifest(issues, _manifest),
    do: [error("$.cadence_import_manifest", "must be an object") | issues]

  defp validate_optional_operational_feedback_provenance(issues, artifact) do
    case Map.get(artifact, "operational_feedback_provenance") do
      value when value in [nil, :null] ->
        issues

      %{} = provenance ->
        issues
        |> require_fields(@provenance_path, provenance, @provenance_fields)
        |> expect_equal(@provenance_path, provenance, "model", @provenance_model)
        |> expect_type(@provenance_path, provenance, "merge_order", :list)
        |> expect_type(@provenance_path, provenance, "input_keys", :list)
        |> expect_type(@provenance_path, provenance, "effective_sources", :map)
        |> expect_type(@provenance_path, provenance, "overridden_sources", :map)
        |> expect_type(@provenance_path, provenance, "source_count", :integer)
        |> expect_non_negative_integer(@provenance_path, provenance, "source_count")
        |> expect_type(@provenance_path, provenance, "sources", :list)
        |> expect_type(@provenance_path, provenance, "explicit_request_override", :boolean)
        |> validate_unique_string_list(
          "#{@provenance_path}.merge_order",
          provenance["merge_order"],
          false
        )
        |> validate_unique_string_list(
          "#{@provenance_path}.input_keys",
          provenance["input_keys"],
          true
        )
        |> validate_source_rows(provenance["sources"])
        |> validate_source_count(provenance)
        |> validate_source_resolution(provenance)
        |> validate_feedback_input_keys(provenance, artifact["operational_feedback"])

      _value ->
        [error(@provenance_path, "must be an object") | issues]
    end
  end

  defp validate_source_rows(issues, rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = row, index}, acc ->
        path = "#{@provenance_path}.sources[#{index}]"

        acc
        |> require_fields(path, row, ["source", "input_keys"])
        |> expect_type(path, row, "source", :binary)
        |> expect_type(path, row, "input_keys", :list)
        |> validate_unique_string_list("#{path}.input_keys", row["input_keys"], true)

      {_row, index}, acc ->
        [error("#{@provenance_path}.sources[#{index}]", "must be an object") | acc]
    end)
  end

  defp validate_source_rows(issues, _rows), do: issues

  defp validate_source_count(issues, %{"sources" => rows, "source_count" => count})
       when is_list(rows) and is_integer(count) do
    if count == length(rows) do
      issues
    else
      [error("#{@provenance_path}.source_count", "must equal sources row count") | issues]
    end
  end

  defp validate_source_count(issues, _provenance), do: issues

  defp validate_source_resolution(
         issues,
         %{
           "input_keys" => input_keys,
           "effective_sources" => effective_sources,
           "overridden_sources" => overridden_sources,
           "sources" => sources
         }
       )
       when is_list(input_keys) and is_map(effective_sources) and is_map(overridden_sources) and
              is_list(sources) do
    source_names =
      sources
      |> Enum.flat_map(fn
        %{"source" => source} when is_binary(source) -> [source]
        _row -> []
      end)
      |> MapSet.new()

    issues
    |> validate_effective_source_keys(input_keys, effective_sources)
    |> validate_string_source_map(
      "#{@provenance_path}.effective_sources",
      effective_sources,
      source_names
    )
    |> validate_string_source_list_map(
      "#{@provenance_path}.overridden_sources",
      overridden_sources,
      input_keys,
      source_names
    )
  end

  defp validate_source_resolution(issues, _provenance), do: issues

  defp validate_effective_source_keys(issues, input_keys, effective_sources) do
    if Enum.sort(Map.keys(effective_sources)) == input_keys do
      issues
    else
      [
        error(
          "#{@provenance_path}.effective_sources",
          "keys must equal sorted operational-feedback input keys"
        )
        | issues
      ]
    end
  end

  defp validate_string_source_map(issues, path, values, source_names) do
    Enum.reduce(values, issues, fn {key, value}, acc ->
      cond do
        not is_binary(key) ->
          [error(path, "keys must be strings") | acc]

        not is_binary(value) ->
          [error("#{path}.#{key}", "must be a string") | acc]

        not MapSet.member?(source_names, value) ->
          [error("#{path}.#{key}", "must reference a declared source") | acc]

        true ->
          acc
      end
    end)
  end

  defp validate_string_source_list_map(issues, path, values, input_keys, source_names) do
    input_key_set = MapSet.new(input_keys)

    Enum.reduce(values, issues, fn {key, source_values}, acc ->
      acc =
        if is_binary(key) and MapSet.member?(input_key_set, key) do
          acc
        else
          [error(path, "keys must reference operational-feedback input keys") | acc]
        end

      case source_values do
        values when is_list(values) ->
          values
          |> Enum.with_index()
          |> Enum.reduce(acc, fn {source, index}, nested_acc ->
            if is_binary(source) and MapSet.member?(source_names, source) do
              nested_acc
            else
              [error("#{path}.#{key}[#{index}]", "must reference a declared source") | nested_acc]
            end
          end)

        _value ->
          [error("#{path}.#{key}", "must be a list") | acc]
      end
    end)
  end

  defp validate_feedback_input_keys(issues, provenance, %{} = operational_feedback) do
    expected_input_keys =
      @operational_feedback_fields
      |> Enum.filter(fn field ->
        case Map.get(operational_feedback, field) do
          %{} = values -> map_size(values) > 0
          _value -> false
        end
      end)
      |> Enum.sort()

    if provenance["input_keys"] == expected_input_keys do
      issues
    else
      [
        error(
          "#{@provenance_path}.input_keys",
          "must equal nonempty operational-feedback field keys"
        )
        | issues
      ]
    end
  end

  defp validate_feedback_input_keys(issues, _provenance, _operational_feedback), do: issues

  defp validate_unique_string_list(issues, path, values, sorted?) when is_list(values) do
    issues =
      values
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {value, index}, acc ->
        if is_binary(value), do: acc, else: [error("#{path}[#{index}]", "must be a string") | acc]
      end)

    cond do
      Enum.uniq(values) != values -> [error(path, "must contain unique values") | issues]
      sorted? and Enum.sort(values) != values -> [error(path, "must be sorted") | issues]
      true -> issues
    end
  end

  defp validate_unique_string_list(issues, _path, _values, _sorted?), do: issues
end
