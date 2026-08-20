defmodule OrbitalDynamics.Optimizer.HardFeasibility do
  @moduledoc false

  alias OrbitalDynamics.Communications.DownlinkLinkBudget
  alias OrbitalDynamics.ResourceStateTrace

  @stable_id ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @sha256 ~r/^[0-9a-f]{64}$/
  @max_float 1.7976931348623157e308
  @config_fields ~w(mode parameter_revision candidates)
  @candidate_fields ~w(
    alternative_id parameter_revision parameter_content_identity spacecraft_id
    resource_state_trace resource_state_trace_id resource_state_trace_revision resource_threshold
    downlink_link_budget downlink_link_budget_id downlink_link_budget_revision downlink_threshold
  )
  @resource_metric "minimum_battery_state_of_charge"
  @downlink_metrics %{
    "completion_fraction" => "greater_than_or_equal",
    "shortfall_mb" => "less_than_or_equal"
  }
  @model_limits [
    "caller_supplied_candidate_evidence_only",
    "one_resource_state_trace_per_candidate",
    "one_downlink_link_budget_per_candidate",
    "one_resource_state_threshold_per_candidate",
    "one_downlink_threshold_per_candidate",
    "resource_threshold_uses_trace_states_without_new_propagation",
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
      resource_metrics: [@resource_metric],
      downlink_metrics: @downlink_metrics |> Map.keys() |> Enum.sort(),
      evidence_sources: ["resource_state_trace.v1", "downlink_link_budget.v1"],
      model_limits: @model_limits
    }
  end

  def model_limits, do: @model_limits

  def search_model_limits(legacy_limits) do
    legacy_limits
    |> Enum.reject(&(&1 == "no_constraint_or_feasibility_evaluation_beyond_bounds"))
    |> Kernel.++(@model_limits)
    |> Enum.uniq()
  end

  def parameter_content_identity(parameters) when is_map(parameters) do
    parameters = stringify!(parameters, "parameters")

    unless map_size(parameters) > 0 and
             Enum.all?(parameters, fn {key, value} ->
               Regex.match?(~r/^[A-Za-z][A-Za-z0-9_.-]*$/, key) and finite?(value)
             end) do
      raise ArgumentError, "parameters must be a non-empty finite numeric map"
    end

    digest =
      parameters
      |> :erlang.term_to_binary([:deterministic])
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    %{"sha256" => digest}
  end

  def parameter_content_identity(_parameters),
    do: raise(ArgumentError, "parameters must be a non-empty finite numeric map")

  def prepare(opts, alternatives) do
    if Keyword.has_key?(opts, :hard_feasibility) do
      config = opts |> Keyword.fetch!(:hard_feasibility) |> stringify!("hard_feasibility")

      unless is_map(config), do: raise(ArgumentError, "hard_feasibility must be a map")
      reject_unknown!(config, @config_fields, "hard_feasibility")

      unless config["mode"] in [:hard, "hard"] do
        raise ArgumentError, "hard_feasibility.mode must be :hard or \"hard\""
      end

      revision = stable_id!(config["parameter_revision"], "parameter_revision")
      rows = Map.get(config, "candidates", [])

      unless is_list(rows) and Enum.all?(rows, &is_map/1) do
        raise ArgumentError, "hard_feasibility candidates must be a list of maps"
      end

      ids = Enum.map(rows, &candidate_id!/1)
      alternative_ids = MapSet.new(alternatives, & &1["id"])

      if duplicate?(ids),
        do: raise(ArgumentError, "hard_feasibility contains duplicate candidate evidence")

      case Enum.find(ids, &(not MapSet.member?(alternative_ids, &1))) do
        nil -> :ok
        id -> raise ArgumentError, "hard_feasibility identifies unknown alternative #{id}"
      end

      {:hard,
       %{
         parameter_revision: revision,
         candidates: Map.new(rows, &{&1["alternative_id"], &1})
       }}
    else
      :legacy
    end
  end

  def evaluate(alternative, config) do
    content_identity = parameter_content_identity(alternative["parameters"])

    case config.candidates[alternative["id"]] do
      nil ->
        evaluation(
          alternative,
          config,
          content_identity,
          nil,
          nil,
          nil,
          [],
          [block("missing_candidate_evidence")]
        )

      candidate ->
        reject_unknown!(candidate, @candidate_fields, "candidate evidence")
        spacecraft_id = candidate["spacecraft_id"]

        blockers =
          []
          |> mismatch(
            candidate["parameter_revision"],
            config.parameter_revision,
            "parameter_revision_mismatch"
          )
          |> content_mismatch(candidate["parameter_content_identity"], content_identity)

        {resource_binding, resource_rows, resource_blockers} = resource(candidate, spacecraft_id)
        {link_binding, link_rows, link_blockers} = downlink(candidate, spacecraft_id)

        evaluation(
          alternative,
          config,
          content_identity,
          spacecraft_id,
          resource_binding,
          link_binding,
          resource_rows ++ link_rows,
          blockers ++ resource_blockers ++ link_blockers
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

  defp resource(candidate, spacecraft_id) do
    trace = candidate["resource_state_trace"]
    id = candidate["resource_state_trace_id"]
    revision = candidate["resource_state_trace_revision"]
    binding = %{"id" => id, "revision" => revision}

    case valid_trace(trace) do
      {:error, detail} ->
        {binding, [], [block("malformed_resource_state_trace", detail: detail)]}

      :ok ->
        blockers =
          mismatches([
            {id, trace["id"], "resource_state_trace_identity_mismatch"},
            {revision, trace_revision(trace), "resource_state_trace_revision_mismatch"},
            {spacecraft_id, trace["spacecraft_id"], "resource_state_trace_spacecraft_mismatch"}
          ])

        cond do
          blockers != [] ->
            {binding, [], blockers}

          trace["status"] not in ["clear", "limit_exceeded"] ->
            {binding, [], [block("resource_state_trace_not_evaluable")]}

          true ->
            {row, threshold_blockers} =
              resource_threshold(trace, candidate["resource_threshold"])

            {binding, List.wrap(row), threshold_blockers}
        end
    end
  end

  defp downlink(candidate, spacecraft_id) do
    budget = candidate["downlink_link_budget"]
    id = candidate["downlink_link_budget_id"]
    revision = candidate["downlink_link_budget_revision"]
    binding = %{"id" => id, "revision" => revision}

    case DownlinkLinkBudget.validate_artifact(budget) do
      {:error, detail} ->
        {binding, [], [block("malformed_downlink_link_budget", detail: detail)]}

      :ok ->
        blockers =
          mismatches([
            {id, budget["id"], "downlink_link_budget_identity_mismatch"},
            {revision, get_in(budget, ["provenance", "source_revision"]),
             "downlink_link_budget_revision_mismatch"},
            {spacecraft_id, get_in(budget, ["contact_binding", "spacecraft_id"]),
             "downlink_link_budget_spacecraft_mismatch"}
          ])

        if blockers == [] do
          {row, threshold_blockers} = downlink_threshold(budget, candidate["downlink_threshold"])
          {binding, List.wrap(row), threshold_blockers}
        else
          {binding, [], blockers}
        end
    end
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

      true ->
        resource_row(trace, threshold)
    end
  end

  defp resource_threshold(_trace, _threshold),
    do: {nil, [block("malformed_resource_threshold")]}

  defp downlink_threshold(_budget, nil), do: {nil, [block("missing_downlink_threshold")]}

  defp downlink_threshold(budget, threshold) when is_map(threshold) do
    cond do
      Enum.any?(
        Map.keys(threshold),
        &(&1 not in ~w(metric operator threshold required_volume_mb))
      ) or Map.get(@downlink_metrics, threshold["metric"]) != threshold["operator"] ->
        {nil, [block("unsupported_downlink_threshold")]}

      not finite?(threshold["threshold"]) or not finite?(threshold["required_volume_mb"]) or
          threshold["required_volume_mb"] <= 0 ->
        {nil, [block("malformed_downlink_threshold")]}

      true ->
        downlink_row(budget, threshold)
    end
  end

  defp downlink_threshold(_budget, _threshold),
    do: {nil, [block("malformed_downlink_threshold")]}

  defp resource_row(trace, threshold) do
    states =
      [trace["initial_state"]] ++
        Enum.flat_map(trace["trace_rows"], &[&1["state_before"], &1["state_after"]]) ++
        [trace["final_state"]]

    values = Enum.map(states, &Map.fetch!(&1, "battery_state_of_charge"))
    unless Enum.all?(values, &finite?/1), do: raise(ArgumentError, "malformed resource metric")
    actual = Enum.min(values)
    threshold_row("resource_state_threshold", "resource_state_trace.v1", threshold, actual, %{})
  rescue
    _error ->
      {%{"type" => "resource_state_threshold", "status" => "invalid"},
       [block("malformed_resource_state_trace")]}
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
  rescue
    _error ->
      {%{"type" => "downlink_threshold", "status" => "invalid"},
       [block("malformed_downlink_link_budget")]}
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
      if passed do
        []
      else
        [
          block(reason,
            metric: threshold["metric"],
            actual: actual,
            operator: threshold["operator"],
            threshold: threshold["threshold"]
          )
        ]
      end

    {row, blockers}
  end

  defp valid_trace(trace) when is_map(trace) do
    required =
      ~w(schema_contract id model spacecraft_id status initial_state final_state trace_rows provenance)

    cond do
      Enum.any?(required, &(not Map.has_key?(trace, &1))) ->
        {:error, "missing required fields"}

      trace["schema_contract"] != "resource_state_trace.v1" ->
        {:error, "unexpected contract"}

      trace["model"] != ResourceStateTrace.model() ->
        {:error, "unexpected model"}

      not is_list(trace["trace_rows"]) or not is_map(trace["initial_state"]) or
        not is_map(trace["final_state"]) or not is_map(trace["provenance"]) ->
        {:error, "malformed structure"}

      trace["id"] != ResourceStateTrace.artifact_id(Map.delete(trace, "id")) ->
        {:error, "content identity mismatch"}

      true ->
        :ok
    end
  rescue
    _error -> {:error, "malformed resource-state trace"}
  end

  defp valid_trace(_trace), do: {:error, "resource-state trace must be a map"}

  defp trace_revision(trace),
    do: get_in(trace, ["provenance", "caller", "resource_state_trace_revision"])

  defp evaluation(
         alternative,
         config,
         content_identity,
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
      "parameter_revision" => config.parameter_revision,
      "parameter_content_identity" => content_identity,
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

  defp content_mismatch(blockers, %{"sha256" => digest} = declared, expected)
       when map_size(declared) == 1 and is_binary(digest) do
    cond do
      not Regex.match?(@sha256, digest) ->
        blockers ++ [block("malformed_parameter_content_identity")]

      declared != expected ->
        blockers ++ [block("parameter_content_identity_mismatch")]

      true ->
        blockers
    end
  end

  defp content_mismatch(blockers, _declared, _expected),
    do: blockers ++ [block("malformed_parameter_content_identity")]

  defp mismatch(blockers, left, right, reason),
    do: if(left == right and not is_nil(left), do: blockers, else: blockers ++ [block(reason)])

  defp mismatches(checks) do
    Enum.flat_map(checks, fn {left, right, reason} ->
      if left == right and not is_nil(left), do: [], else: [block(reason)]
    end)
  end

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

  defp stable_id!(value, label) do
    if is_binary(value) and Regex.match?(@stable_id, value) do
      value
    else
      raise ArgumentError, "hard_feasibility.#{label} must be a stable identity"
    end
  end

  defp finite?(value) when is_number(value),
    do: value == value and value <= @max_float and value >= -@max_float

  defp finite?(_value), do: false
  defp duplicate?(values), do: length(values) != length(Enum.uniq(values))

  defp stringify!(map, label) when is_map(map) do
    entries =
      Enum.map(map, fn {key, value} ->
        {string_key!(key, label), stringify!(value, label)}
      end)

    keys = Enum.map(entries, &elem(&1, 0))

    if duplicate?(keys),
      do: raise(ArgumentError, "#{label} contains duplicate keys after key normalization")

    Map.new(entries)
  end

  defp stringify!(list, label) when is_list(list),
    do: Enum.map(list, &stringify!(&1, label))

  defp stringify!(value, _label), do: value
  defp string_key!(key, _label) when is_atom(key), do: Atom.to_string(key)
  defp string_key!(key, _label) when is_binary(key), do: key

  defp string_key!(_key, label),
    do: raise(ArgumentError, "#{label} keys must be atoms or strings")
end
