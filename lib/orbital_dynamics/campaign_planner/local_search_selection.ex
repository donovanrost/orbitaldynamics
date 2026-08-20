defmodule OrbitalDynamics.CampaignPlanner.LocalSearchSelection do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{BuildArtifact, BuildOrchestration}
  alias OrbitalDynamics.Schema.JsonSafety
  alias OrbitalDynamics.Search.Local
  alias OrbitalDynamics.{Optimizer, ResultSet}

  @selection_contract "v1_outer_local_search_inner_greedy"
  @objective "maximize first ranked timeline aggregate score"
  @score_term "first_ranked_timeline_score"
  @default_id_prefix "campaign_v1"
  @search_fields ~w(steps bounds id_prefix max_alternatives hard_feasibility)
  @numeric_policy_keys ~w(
    target_value_weight
    contact_value_weight
    eclipse_penalty_weight
    downlink_rate_mb_s
    activity_count_penalty
    required_downlink_mb
    downlink_completion_weight
    timeline_precondition_weight
    resource_projection_weight
  )

  def selection_contract, do: @selection_contract
  def numeric_policy_keys, do: @numeric_policy_keys

  def build(%ResultSet{} = result_set, campaign, generated_at, local_search) do
    campaign = normalize_campaign!(campaign)
    search = normalize_search!(local_search)
    base_policy = scoring_policy!(campaign)
    seed_parameters = seed_parameters!(base_policy)
    optimizer_opts = optimizer_opts!(search, seed_parameters)

    neighborhood =
      Local.neighborhood(
        seed_parameters,
        Keyword.take(optimizer_opts, [:steps, :bounds, :id_prefix, :max_alternatives])
      )

    plans =
      Map.new(neighborhood["alternatives"], fn alternative ->
        policy = Map.merge(base_policy, alternative["parameters"])
        effective_campaign = Map.put(campaign, "scoring_policy", policy)
        plan = BuildOrchestration.build(result_set, effective_campaign, generated_at)

        {alternative["id"],
         %{
           plan: plan,
           policy: policy,
           score: first_ranked_timeline_score(plan)
         }}
      end)

    plan_scores_by_parameters =
      Map.new(neighborhood["alternatives"], fn alternative ->
        plan = Map.fetch!(plans, alternative["id"])
        {alternative["parameters"], plan.score}
      end)

    search_result =
      Optimizer.explainable_local_search(
        seed_parameters,
        fn parameters ->
          %{@score_term => Map.fetch!(plan_scores_by_parameters, parameters)}
        end,
        Keyword.merge(optimizer_opts,
          objective: @objective,
          objective_direction: :maximize
        )
      )

    first_alternative_id = neighborhood["alternatives"] |> List.first() |> Map.fetch!("id")

    plan_id =
      plans |> Map.fetch!(first_alternative_id) |> Map.fetch!(:plan) |> Map.fetch!("plan_id")

    selected_id = search_result["selected_id"]
    selected = if selected_id, do: Map.fetch!(plans, selected_id)
    trace = trace(plan_id, campaign, base_policy, selected, search_result)

    if selected do
      BuildArtifact.attach_optimizer_search_trace(selected.plan, trace)
    else
      {:no_selected_plan, trace}
    end
  end

  defp normalize_campaign!(campaign) when is_map(campaign) do
    campaign = JsonSafety.normalize_input!(campaign, "campaign")

    unless is_map(Map.get(campaign, "constraints", %{})) do
      raise ArgumentError, "campaign.constraints must be a map"
    end

    campaign
  end

  defp normalize_campaign!(_campaign), do: raise(ArgumentError, "campaign must be a map")

  defp normalize_search!(local_search) when is_map(local_search) do
    search = JsonSafety.normalize_input!(local_search, "local_search")

    case Enum.find(Map.keys(search), &(&1 not in @search_fields)) do
      nil -> :ok
      field -> raise ArgumentError, "local_search contains unsupported field #{field}"
    end

    unless Map.has_key?(search, "steps") do
      raise ArgumentError, "local_search.steps is required"
    end

    unless Map.has_key?(search, "hard_feasibility") do
      raise ArgumentError, "local_search.hard_feasibility is required"
    end

    search
  end

  defp normalize_search!(_local_search),
    do: raise(ArgumentError, "local_search must be a JSON-safe map")

  defp scoring_policy!(campaign) do
    case Map.get(campaign, "scoring_policy", %{}) do
      %{} = policy ->
        Enum.each(@numeric_policy_keys, fn key ->
          if Map.has_key?(policy, key) and not is_number(policy[key]) do
            raise ArgumentError, "campaign.scoring_policy.#{key} must be a finite number"
          end
        end)

        policy

      _policy ->
        raise ArgumentError, "campaign.scoring_policy must be a map"
    end
  end

  defp seed_parameters!(base_policy) do
    parameters = Map.take(base_policy, @numeric_policy_keys)

    if map_size(parameters) == 0 do
      raise ArgumentError,
            "campaign.scoring_policy must declare at least one supported numeric search key"
    end

    parameters
  end

  defp optimizer_opts!(search, seed_parameters) do
    steps = numeric_map!(search["steps"], "local_search.steps", allow_empty?: false)
    reject_unsupported_policy_keys!(steps, "local_search.steps")

    seed_keys = seed_parameters |> Map.keys() |> MapSet.new()

    case Enum.find(Map.keys(steps), &(not MapSet.member?(seed_keys, &1))) do
      nil ->
        :ok

      key ->
        raise ArgumentError,
              "local_search.steps key #{key} is not present in campaign.scoring_policy"
    end

    if Enum.any?(steps, fn {_key, step} -> step <= 0 end) do
      raise ArgumentError, "local_search.steps must contain only positive finite numbers"
    end

    bounds = bounds!(Map.get(search, "bounds", %{}), seed_keys)
    id_prefix = Map.get(search, "id_prefix", @default_id_prefix)

    max_alternatives =
      Map.get(search, "max_alternatives", Local.capabilities().default_max_alternatives)

    unless is_binary(id_prefix) and id_prefix != "" do
      raise ArgumentError, "local_search.id_prefix must be a non-empty string"
    end

    unless is_integer(max_alternatives) do
      raise ArgumentError, "local_search.max_alternatives must be an integer"
    end

    [
      steps: steps,
      bounds: bounds,
      id_prefix: id_prefix,
      max_alternatives: max_alternatives,
      hard_feasibility: search["hard_feasibility"]
    ]
  end

  defp numeric_map!(value, label, opts) when is_map(value) do
    allow_empty? = Keyword.fetch!(opts, :allow_empty?)

    cond do
      map_size(value) == 0 and not allow_empty? ->
        raise ArgumentError, "#{label} must be a non-empty map"

      Enum.any?(value, fn {_key, number} -> not is_number(number) end) ->
        raise ArgumentError, "#{label} must contain only finite numbers"

      true ->
        value
    end
  end

  defp numeric_map!(_value, label, _opts), do: raise(ArgumentError, "#{label} must be a map")

  defp bounds!(bounds, seed_keys) when is_map(bounds) do
    reject_unsupported_policy_keys!(bounds, "local_search.bounds")

    Map.new(bounds, fn {key, range} ->
      unless MapSet.member?(seed_keys, key) do
        raise ArgumentError,
              "local_search.bounds key #{key} is not present in campaign.scoring_policy"
      end

      case range do
        [minimum, maximum] when is_number(minimum) and is_number(maximum) ->
          {key, {minimum, maximum}}

        _range ->
          raise ArgumentError,
                "local_search.bounds.#{key} must be a two-number JSON array"
      end
    end)
  end

  defp bounds!(_bounds, _seed_keys),
    do: raise(ArgumentError, "local_search.bounds must be a map")

  defp reject_unsupported_policy_keys!(map, label) do
    case Enum.find(Map.keys(map), &(&1 not in @numeric_policy_keys)) do
      nil -> :ok
      key -> raise ArgumentError, "#{label} contains unsupported V1 scoring key #{key}"
    end
  end

  defp first_ranked_timeline_score(plan) do
    plan
    |> Map.get("ranked_timelines", [])
    |> List.first(%{})
    |> Map.get("score", 0.0)
  end

  defp trace(plan_id, campaign, base_policy, selected, search_result) do
    selected_alternative =
      Enum.find(search_result["alternatives"], &(&1["id"] == search_result["selected_id"]))

    selected_plan = if selected, do: selected.plan
    selected_timeline = selected_plan && List.first(selected_plan["ranked_timelines"])
    selected_activity_ids = selected_plan |> selected_activity_ids()

    %{
      "schema_contract" => "campaign_plan_search_trace.v1",
      "id" => "campaign_plan_search_trace:#{plan_id}",
      "plan_id" => plan_id,
      "status" => if(selected, do: "selected_plan", else: "no_selected_plan"),
      "selection_contract" => @selection_contract,
      "objective" => @objective,
      "objective_direction" => "maximize",
      "base_scoring_policy" => base_policy,
      "selected_scoring_policy" => if(selected, do: selected.policy),
      "searched_scoring_policy_keys" =>
        get_in(search_result, ["neighborhood", "step_parameters"]),
      "fixed_constraints" => Map.get(campaign, "constraints", %{}),
      "selected_alternative_id" => search_result["selected_id"],
      "selected_alternative" => selected_alternative,
      "selected_timeline_scenario_id" => selected_timeline && selected_timeline["scenario_id"],
      "selected_timeline_score" => selected_timeline && selected_timeline["score"],
      "selected_activity_ids" => selected_activity_ids,
      "selected_activity_count" => length(selected_activity_ids),
      "search_result" => search_result
    }
  end

  defp selected_activity_ids(nil), do: []

  defp selected_activity_ids(plan) do
    plan
    |> Map.get("activities", [])
    |> Enum.map(& &1["id"])
  end
end
