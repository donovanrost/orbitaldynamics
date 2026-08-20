defmodule OrbitalDynamics.CampaignPlanner do
  @moduledoc """
  Deterministic campaign planner for LEO constellation studies.

  The planner consumes propagated event products and emits a compact,
  reproducible plan artifact. V1 deliberately uses transparent greedy timeline
  selection over candidate observation and contact windows instead of hidden
  optimization machinery.

  V2 adds a rolling repair pass over a prior campaign artifact. It compares the
  prior plan against realized operations, preserves approved or executed work
  where policy allows, and repairs the remaining horizon from the prior
  candidate windows.

  V3 compares explicit future branches from a common mission-state snapshot,
  reuses V2 repair inside each branch, and recommends a strategy with
  campaign-level tradeoffs and approval boundaries.
  """

  alias OrbitalDynamics.CampaignPlanner.{
    BuildOrchestration,
    LocalSearchSelection,
    ModelLimits,
    RequestIO,
    RepairOrchestration,
    RepairRequestNormalization,
    ReplanRequest,
    StrategyOrchestration,
    StrategyRequestNormalization
  }

  alias OrbitalDynamics.ResultSet

  @doc """
  Returns the declared model limits for score explanation reports.
  """
  def score_report_model_limits, do: ModelLimits.score_report_model_limits()

  @doc """
  Returns the declared model limits for objective satisfaction reports.
  """
  def objective_satisfaction_model_limits, do: ModelLimits.objective_satisfaction_model_limits()

  @doc """
  Returns the declared model limits for branch comparison reports.
  """
  def branch_comparison_model_limits, do: ModelLimits.branch_comparison_model_limits()

  @doc """
  Returns the declared model limits for realized state snapshot reports.
  """
  def realized_state_snapshot_model_limits, do: ModelLimits.realized_state_snapshot_model_limits()

  @doc """
  Builds a campaign-plan artifact from a completed result set.
  """
  def build(%ResultSet{} = result_set, opts \\ []) do
    campaign = Keyword.fetch!(opts, :campaign)
    generated_at = Keyword.get_lazy(opts, :generated_at, &DateTime.utc_now/0)

    BuildOrchestration.build(result_set, campaign, generated_at)
  end

  @doc """
  Builds a V1 campaign plan through a separate bounded local-search path.

  The `:campaign` and `:local_search` options are required. `:local_search`
  must be a JSON-safe map containing `steps`, optional JSON-array `bounds`, an
  optional `id_prefix` and `max_alternatives`, and required typed
  `hard_feasibility` evidence. The seed and objective are always derived from
  the campaign and cannot be supplied by the caller.

  This function leaves `build/2` unchanged. It returns a selected campaign plan
  or `{:no_selected_plan, trace}` when all alternatives are infeasible.
  """
  def build_with_local_search(%ResultSet{} = result_set, opts) when is_list(opts) do
    unless Keyword.keyword?(opts) do
      raise ArgumentError, "local-search campaign options must be a keyword list"
    end

    option_keys = Keyword.keys(opts)

    if length(option_keys) != length(Enum.uniq(option_keys)) do
      raise ArgumentError, "local-search campaign options contain duplicate keys"
    end

    allowed_keys = [:campaign, :generated_at, :local_search]

    case Enum.find(option_keys, &(&1 not in allowed_keys)) do
      nil -> :ok
      key -> raise ArgumentError, "unsupported local-search campaign option #{inspect(key)}"
    end

    campaign = Keyword.fetch!(opts, :campaign)
    local_search = Keyword.fetch!(opts, :local_search)
    generated_at = Keyword.get_lazy(opts, :generated_at, &DateTime.utc_now/0)

    LocalSearchSelection.build(result_set, campaign, generated_at, local_search)
  end

  def build_with_local_search(%ResultSet{}, _opts) do
    raise ArgumentError, "local-search campaign options must be a keyword list"
  end

  @doc """
  Repairs a prior campaign plan against realized operations.

  The request may be a `%ReplanRequest{}` or a map with string or atom keys:

    * `prior_plan` / `"prior_plan"` - V1 campaign plan artifact.
    * `realized_state` / `"realized_state"` - realized activities plus optional
      spacecraft degraded-mode inputs.
    * `current_epoch_s` / `"current_epoch_s"` - repair epoch in seconds since
      the source plan epoch.
    * `remaining_horizon` / `"remaining_horizon"` - optional map containing
      `starts_at_s` and `ends_at_s`.
    * `constraints`, `scoring_policy`, `repair_policy`, and `approval_policy`
      override source plan defaults for the repair pass.
    * `candidate_refresh_request` / `"candidate_refresh_request"` - optional
      executable refresh manifest. When present and no prebuilt
      `candidate_refresh` is supplied, repair runs the refresh before selecting
      replacement candidates.
    * `ground_network` / `"ground_network"` or `station_calendar` /
      `"station_calendar"` - optional repair-time station availability and
      capacity intervals that annotate source contact candidates.
  """
  def repair(%ReplanRequest{} = request) do
    request
    |> RepairRequestNormalization.normalize()
    |> RepairOrchestration.run()
  end

  def repair(%{} = request) do
    request
    |> RepairRequestNormalization.from_map()
    |> repair()
  end

  def repair!(request) do
    case repair(request) do
      %{} = artifact -> artifact
    end
  end

  @doc """
  Loads a JSON V2 repair request file and returns a repair artifact.

  The request may contain either an inline `prior_plan` or a `source_plan_ref`
  object with `path` and optional `artifact_key`. Relative source paths are
  resolved from the current working directory first, then relative to the
  request file directory. This keeps checked-in example requests executable
  while preserving the artifact-only boundary.
  """
  def repair_from_file!(path, opts \\ []) when is_binary(path) do
    path
    |> RequestIO.load_json_request!()
    |> RequestIO.put_referenced_prior_plan!(path, opts)
    |> repair!()
  end

  @doc """
  Compares explicit future branches and returns a V3 strategy artifact.

  The strategy layer reuses V2 repair inside every branch. Branch events alter
  the prior plan, realized state, and policy inputs before repair; branch
  scoring then compares mission value, risk, approvals, schedule stability,
  downlink completion, fuel preservation, and asset balance.
  """
  def strategy(%{} = request) do
    request
    |> StrategyRequestNormalization.normalize()
    |> StrategyOrchestration.run()
  end

  def strategy!(request), do: strategy(request)

  @doc """
  Loads a JSON V3 strategy request file and returns a strategy artifact.

  The request may contain either an inline `prior_plan` or a `source_plan_ref`
  object with `path` and optional `artifact_key`. Relative source paths are
  resolved from the current working directory first, then relative to the
  request file directory.
  """
  def strategy_from_file!(path, opts \\ []) when is_binary(path) do
    path
    |> RequestIO.load_json_request!()
    |> RequestIO.put_referenced_prior_plan!(path, opts)
    |> strategy!()
  end

  @doc """
  Validates a JSON campaign repair or strategy request without running planning.

  The report checks the request file can be read and decoded as an object, that
  it matches the requested type when `request_type` is present, and that the
  prior campaign plan can be resolved either inline or through `source_plan_ref`.
  It intentionally does not run V2 repair, V3 strategy, candidate refresh, or
  write output artifacts.
  """
  def request_validation_report(type, path, opts \\ [])

  def request_validation_report(type, path, opts) when is_binary(path) do
    RequestIO.validation_report(type, path, opts)
  end
end
