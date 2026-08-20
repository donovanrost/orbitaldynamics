defmodule OrbitalDynamics.Optimizer.HardFeasibility do
  @moduledoc false

  alias OrbitalDynamics.Communications.DownlinkLinkBudget
  alias OrbitalDynamics.Optimizer.SourceEvidenceRegistry
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.JsonSafety

  @stable_id ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @max_float 1.7976931348623157e308
  @config_fields ~w(mode evidence_registry candidates)
  @candidate_fields ~w(
    alternative_id resource_state_trace resource_threshold
    downlink_link_budget downlink_threshold
  )
  @resource_metric "minimum_battery_state_of_charge"
  @downlink_metrics %{
    "completion_fraction" => "greater_than_or_equal",
    "shortfall_mb" => "less_than_or_equal"
  }
  @model_limits [
    "caller_supplied_candidate_evidence_only",
    "caller_supplied_trusted_composition_registry_not_authentication",
    "no_registry_signature_or_authentication",
    "coordinated_registry_and_artifact_replacement_out_of_scope",
    "one_resource_state_trace_per_candidate",
    "one_downlink_link_budget_per_candidate",
    "registry_routes_candidate_parameters_to_exact_source_artifact_ids",
    "one_resource_state_threshold_per_candidate",
    "one_downlink_threshold_per_candidate",
    "resource_threshold_uses_semantically_validated_trace_states",
    "downlink_completion_uses_supported_volume_and_declared_required_volume",
    "no_cross_candidate_resource_allocation",
    "no_operational_calibration_or_network_truth",
    "no_schedule_mutation_or_post_ranking_repair",
    "no_solver_execution"
  ]

  def capabilities do
    %{
      mode: :hard,
      option: :hard_feasibility,
      evaluation_contract: "candidate_feasibility.v1",
      outcome_contract: "local_search_recommendation_outcome.v1",
      evidence_registry_contract: SourceEvidenceRegistry.schema_contract(),
      evidence_registry_trust_boundary: SourceEvidenceRegistry.trust_boundary(),
      resource_metrics: [@resource_metric],
      downlink_metrics: @downlink_metrics |> Map.keys() |> Enum.sort(),
      evidence_sources: ["resource_state_trace.v1", "downlink_link_budget.v1"],
      model_limits: @model_limits
    }
  end

  def model_limits, do: @model_limits

  def registry_summary(config),
    do: Map.take(config.registry, ["schema_contract", "id", "trust_boundary"])

  def search_model_limits(legacy_limits) do
    legacy_limits
    |> Enum.reject(&(&1 == "no_constraint_or_feasibility_evaluation_beyond_bounds"))
    |> Kernel.++(@model_limits)
    |> Enum.uniq()
  end

  def parameter_content_identity(parameters),
    do: SourceEvidenceRegistry.parameter_content_identity(parameters)

  def prepare(opts, alternatives) do
    if Keyword.has_key?(opts, :hard_feasibility) do
      config =
        opts
        |> Keyword.fetch!(:hard_feasibility)
        |> JsonSafety.normalize_input!("hard_feasibility")

      unless is_map(config), do: raise(ArgumentError, "hard_feasibility must be a map")
      reject_unknown!(config, @config_fields, "hard_feasibility")

      unless config["mode"] == "hard",
        do: raise(ArgumentError, "hard_feasibility.mode must be :hard or \"hard\"")

      registry = SourceEvidenceRegistry.normalize!(config["evidence_registry"])
      rows = Map.get(config, "candidates", [])

      unless is_list(rows) and Enum.all?(rows, &is_map/1),
        do: raise(ArgumentError, "hard_feasibility candidates must be a list of maps")

      ids = Enum.map(rows, &candidate_id!/1)
      alternative_ids = MapSet.new(alternatives, & &1["id"])

      if duplicate?(ids),
        do: raise(ArgumentError, "hard_feasibility contains duplicate candidate evidence")

      case Enum.find(ids, &(not MapSet.member?(alternative_ids, &1))) do
        nil -> :ok
        id -> raise ArgumentError, "hard_feasibility identifies unknown alternative #{id}"
      end

      case Enum.find(Map.keys(registry["entries"]), &(not MapSet.member?(alternative_ids, &1))) do
        nil -> :ok
        id -> raise ArgumentError, "source evidence registry identifies unknown alternative #{id}"
      end

      {:hard,
       %{
         registry: registry,
         registry_id: registry["id"],
         candidates: Map.new(rows, &{&1["alternative_id"], &1})
       }}
    else
      :legacy
    end
  end

  def evaluate(alternative, config) do
    registry_entry = config.registry["entries"][alternative["id"]]
    candidate = config.candidates[alternative["id"]]

    case {registry_entry, candidate} do
      {nil, _candidate} ->
        evaluation(alternative, config, nil, nil, nil, nil, [], [
          block("missing_source_evidence_registry_entry")
        ])

      {registry_entry, nil} ->
        evaluation(alternative, config, registry_entry, nil, nil, nil, [], [
          block("missing_candidate_evidence")
        ])

      {registry_entry, candidate} ->
        reject_unknown!(candidate, @candidate_fields, "candidate evidence")

        parameter_blockers =
          if SourceEvidenceRegistry.parameter_content_identity(alternative["parameters"]) ==
               registry_entry["parameter_content_identity"],
             do: [],
             else: [block("parameter_content_identity_registry_mismatch")]

        {resource_binding, resource_rows, resource_blockers, resource_spacecraft_id} =
          resource(candidate, registry_entry)

        {link_binding, link_rows, link_blockers, link_spacecraft_id} =
          downlink(candidate, registry_entry)

        spacecraft_blockers =
          if resource_spacecraft_id && link_spacecraft_id &&
               resource_spacecraft_id != link_spacecraft_id,
             do: [block("candidate_evidence_spacecraft_mismatch")],
             else: []

        spacecraft_id =
          if spacecraft_blockers == [], do: resource_spacecraft_id || link_spacecraft_id

        evaluation(
          alternative,
          config,
          registry_entry,
          spacecraft_id,
          resource_binding,
          link_binding,
          resource_rows ++ link_rows,
          parameter_blockers ++ resource_blockers ++ link_blockers ++ spacecraft_blockers
        )
    end
  end

  def outcome(selected, eligible_count, infeasible_count) do
    selected? = not is_nil(selected)

    %{
      "schema_contract" => "local_search_recommendation_outcome.v1",
      "mode" => "hard",
      "status" => if(selected?, do: "recommendable", else: "no_recommendable_alternative"),
      "selected_incumbent_id" => if(selected?, do: selected["id"], else: nil),
      "reason" =>
        if(selected?,
          do: "best_feasible_score_then_generation_order_then_id",
          else: "all_alternatives_infeasible"
        ),
      "eligible_count" => eligible_count,
      "infeasible_count" => infeasible_count
    }
  end

  defp resource(candidate, registry_entry) do
    trace = candidate["resource_state_trace"]
    expected_id = registry_entry["resource_state_trace_id"]
    binding = trace_binding(trace, expected_id)

    case Schema.validate_artifact(trace, schema_contract: "resource_state_trace.v1") do
      {:error, _report} ->
        {binding, [], [block("malformed_resource_state_trace")], nil}

      {:ok, _report} ->
        revision = get_in(trace, ["provenance", "caller", "resource_state_trace_revision"])

        blockers =
          if(trace["id"] == expected_id,
            do: [],
            else: [block("resource_state_trace_registry_identity_mismatch")]
          ) ++
            if(valid_revision?(revision),
              do: [],
              else: [block("resource_state_trace_revision_missing_or_malformed")]
            ) ++
            if(trace["status"] in ["clear", "limit_exceeded"],
              do: [],
              else: [block("resource_state_trace_not_evaluable")]
            )

        binding = %{
          "id" => trace["id"],
          "expected_id" => expected_id,
          "revision" => revision
        }

        if blockers == [] do
          {row, threshold_blockers} = resource_threshold(trace, candidate["resource_threshold"])
          {binding, List.wrap(row), threshold_blockers, trace["spacecraft_id"]}
        else
          {binding, [], blockers, trace["spacecraft_id"]}
        end
    end
  rescue
    _error -> {nil, [], [block("malformed_resource_state_trace")], nil}
  end

  defp downlink(candidate, registry_entry) do
    budget = candidate["downlink_link_budget"]
    expected_id = registry_entry["downlink_link_budget_id"]
    binding = link_binding(budget, expected_id)

    case DownlinkLinkBudget.validate_artifact(budget) do
      {:error, _detail} ->
        {binding, [], [block("malformed_downlink_link_budget")], nil}

      :ok ->
        blockers =
          if budget["id"] == expected_id,
            do: [],
            else: [block("downlink_link_budget_registry_identity_mismatch")]

        spacecraft_id = get_in(budget, ["contact_binding", "spacecraft_id"])

        binding = %{
          "id" => budget["id"],
          "expected_id" => expected_id,
          "revision" => get_in(budget, ["provenance", "source_revision"])
        }

        if blockers == [] do
          {row, threshold_blockers} = downlink_threshold(budget, candidate["downlink_threshold"])
          {binding, List.wrap(row), threshold_blockers, spacecraft_id}
        else
          {binding, [], blockers, spacecraft_id}
        end
    end
  rescue
    _error -> {nil, [], [block("malformed_downlink_link_budget")], nil}
  end

  defp resource_threshold(_trace, nil), do: {nil, [block("missing_resource_threshold")]}

  defp resource_threshold(trace, threshold) when is_map(threshold) do
    cond do
      Enum.any?(Map.keys(threshold), &(&1 not in ~w(metric operator threshold))) or
        threshold["metric"] != @resource_metric or
          threshold["operator"] != "greater_than_or_equal" ->
        {nil, [block("unsupported_resource_threshold")]}

      not finite?(threshold["threshold"]) ->
        {nil, [block("malformed_resource_threshold")]}

      threshold["threshold"] < 0.0 or threshold["threshold"] > 1.0 ->
        {nil, [block("resource_threshold_out_of_domain")]}

      true ->
        actual = minimum_trace_soc(trace)

        threshold_row(
          "resource_state_threshold",
          "resource_state_trace.v1",
          threshold,
          actual,
          %{}
        )
    end
  end

  defp resource_threshold(_trace, _threshold),
    do: {nil, [block("malformed_resource_threshold")]}

  defp downlink_threshold(_budget, nil), do: {nil, [block("missing_downlink_threshold")]}

  defp downlink_threshold(budget, threshold) when is_map(threshold) do
    metric = threshold["metric"]

    cond do
      Enum.any?(
        Map.keys(threshold),
        &(&1 not in ~w(metric operator threshold required_volume_mb))
      ) or Map.get(@downlink_metrics, metric) != threshold["operator"] ->
        {nil, [block("unsupported_downlink_threshold")]}

      not finite?(threshold["threshold"]) or not finite?(threshold["required_volume_mb"]) ->
        {nil, [block("malformed_downlink_threshold")]}

      threshold["required_volume_mb"] <= 0.0 or
        (metric == "completion_fraction" and
           (threshold["threshold"] < 0.0 or threshold["threshold"] > 1.0)) or
          (metric == "shortfall_mb" and threshold["threshold"] < 0.0) ->
        {nil, [block("downlink_threshold_out_of_domain")]}

      true ->
        downlink_row(budget, threshold)
    end
  end

  defp downlink_threshold(_budget, _threshold),
    do: {nil, [block("malformed_downlink_threshold")]}

  defp minimum_trace_soc(trace) do
    ([trace["initial_state"]] ++
       Enum.flat_map(trace["trace_rows"], &[&1["state_before"], &1["state_after"]]) ++
       [trace["final_state"]])
    |> Enum.map(&Map.fetch!(&1, "battery_state_of_charge"))
    |> Enum.min()
  end

  defp downlink_row(budget, threshold) do
    supported = get_in(budget, ["derived", "supported_volume_mb"])
    required = threshold["required_volume_mb"]

    actual =
      if threshold["metric"] == "completion_fraction",
        do: min(supported / required, 1.0),
        else: max(required - supported, 0.0)

    threshold_row("downlink_threshold", "downlink_link_budget.v1", threshold, actual, %{
      "required_volume_mb" => required,
      "supported_volume_mb" => supported
    })
  end

  defp threshold_row(type, contract, threshold, actual, extras) do
    passed = compare(actual, threshold["operator"], threshold["threshold"])

    reason =
      if type == "resource_state_threshold",
        do: "resource_threshold_not_met",
        else: "downlink_threshold_not_met"

    row =
      Map.merge(extras, %{
        "type" => type,
        "source_contract" => contract,
        "metric" => threshold["metric"],
        "operator" => threshold["operator"],
        "actual" => actual,
        "threshold" => threshold["threshold"],
        "status" => if(passed, do: "pass", else: "fail")
      })

    blockers =
      if passed,
        do: [],
        else: [
          block(reason,
            metric: threshold["metric"],
            actual: actual,
            operator: threshold["operator"],
            threshold: threshold["threshold"]
          )
        ]

    {row, blockers}
  end

  defp evaluation(
         alternative,
         config,
         registry_entry,
         spacecraft_id,
         resource_binding,
         link_binding,
         rows,
         blockers
       ) do
    eligible = blockers == []

    %{
      "schema_contract" => "candidate_feasibility.v1",
      "mode" => "hard",
      "alternative_id" => alternative["id"],
      "parameter_revision" => registry_value(registry_entry, "parameter_revision"),
      "parameter_content_identity" =>
        registry_value(registry_entry, "parameter_content_identity"),
      "source_evidence_registry_id" => config.registry_id,
      "spacecraft_id" => spacecraft_id,
      "status" => if(eligible, do: "feasible", else: "infeasible"),
      "eligible" => eligible,
      "evidence_bindings" => %{
        "resource_state_trace" => resource_binding,
        "downlink_link_budget" => link_binding
      },
      "threshold_evaluations" => rows,
      "blocker_reasons" => blockers |> Enum.map(& &1["reason"]) |> Enum.uniq(),
      "blockers" => blockers,
      "model_limits" => @model_limits
    }
  end

  defp trace_binding(trace, expected_id) when is_map(trace),
    do: %{
      "id" => trace["id"],
      "expected_id" => expected_id,
      "revision" => get_in(trace, ["provenance", "caller", "resource_state_trace_revision"])
    }

  defp trace_binding(_trace, expected_id), do: %{"id" => nil, "expected_id" => expected_id}

  defp link_binding(budget, expected_id) when is_map(budget),
    do: %{
      "id" => budget["id"],
      "expected_id" => expected_id,
      "revision" => get_in(budget, ["provenance", "source_revision"])
    }

  defp link_binding(_budget, expected_id), do: %{"id" => nil, "expected_id" => expected_id}

  defp registry_value(nil, _field), do: nil
  defp registry_value(registry_entry, field), do: registry_entry[field]

  defp valid_revision?(value),
    do: is_binary(value) and Regex.match?(@stable_id, value)

  defp compare(actual, "greater_than_or_equal", threshold), do: actual >= threshold
  defp compare(actual, "less_than_or_equal", threshold), do: actual <= threshold

  defp block(reason, fields \\ []) do
    Map.new([
      {"reason", reason}
      | Enum.map(fields, fn {key, value} -> {Atom.to_string(key), value} end)
    ])
  end

  defp candidate_id!(row) do
    case row["alternative_id"] do
      id when is_binary(id) and id != "" -> id
      _id -> raise ArgumentError, "candidate evidence must identify an alternative"
    end
  end

  defp reject_unknown!(map, allowed, label) do
    case Enum.find(Map.keys(map), &(&1 not in allowed)) do
      nil -> :ok
      field -> raise ArgumentError, "#{label} contains unsupported field #{field}"
    end
  end

  defp finite?(value) when is_number(value),
    do: value == value and value <= @max_float and value >= -@max_float

  defp finite?(_value), do: false
  defp duplicate?(values), do: length(values) != length(Enum.uniq(values))
end
