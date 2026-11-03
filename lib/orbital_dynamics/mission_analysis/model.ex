defmodule OrbitalDynamics.MissionAnalysis.Model do
  @moduledoc """
  Mission-specific physics behind the mission-independent analysis runner.

  `prepare/3` receives a request, an asset's explicitly declared payload
  configuration, and caller-owned context. It validates those inputs once and
  returns an opaque evaluation session plus JSON-safe assumptions. The runner
  has no knowledge of targets, celestial bodies, illumination, or imaging.

  `evaluate/3` evaluates one state and its preceding state (or nil). A successful
  evaluation is evidence about required performance, not achieved spacecraft
  behavior. Provider failures return errors; physical infeasibility returns
  failed checks. Models must not change the caller's state or execute actions.
  """

  alias OrbitalDynamics.MissionAnalysis.{Evaluation, Request}
  alias OrbitalDynamics.StateVector

  @callback capabilities() :: map()
  @callback prepare(Request.t(), map(), term()) :: {:ok, term(), map()} | {:error, term()}
  @callback pointing(StateVector.t(), term(), map()) ::
              {:ok, OrbitalDynamics.MissionAnalysis.Attitude.Pointing.t()}
              | {:unknown, term()}
              | {:error, term()}
  @callback activity_mode(map(), term()) ::
              {:ok, OrbitalDynamics.MissionAnalysis.Path.Result.t()} | {:error, term()}
  @doc "Optional complete named scalar conditions for conservative opportunity search on the supplied source."
  @callback opportunity_functions(term(), term(), number()) :: {:ok, [term()]} | {:error, term()}
  @optional_callbacks pointing: 3, activity_mode: 2, opportunity_functions: 3

  @callback evaluate(StateVector.t(), StateVector.t() | nil, term()) ::
              {:ok, Evaluation.t()} | {:error, term()}
end

defmodule OrbitalDynamics.MissionAnalysis.Evaluation do
  @moduledoc """
  Sample-level feasibility checks and predicted outcomes, in explicit units.

  Checks are maps containing a string `id` and boolean `passed`; other fields
  can record thresholds and measured values. Optional signed numeric margins
  carry explicit units and comparison direction; unknown margins are null.
  Positive margins indicate headroom, not a robustness or uncertainty guarantee. Every check must pass for a sample
  to be eligible. Metrics and checks must be JSON-safe after normalization.
  """

  alias OrbitalDynamics.Schema.JsonSafety

  @enforce_keys [:checks, :metrics]
  defstruct [:checks, :metrics]
  @type t :: %__MODULE__{checks: [map()], metrics: map()}

  def new!(checks, metrics) when is_list(checks) and is_map(metrics) do
    checks = JsonSafety.normalize_input!(checks, "mission checks")
    metrics = JsonSafety.normalize_input!(metrics, "mission metrics")

    unless checks != [] and
             Enum.all?(checks, fn check ->
               is_map(check) and is_binary(check["id"]) and check["id"] != "" and
                 is_boolean(check["passed"])
             end) do
      raise ArgumentError, "evaluations require nonempty named boolean checks"
    end

    Enum.each(checks, fn check ->
      if Enum.any?(~w(margin margin_unit margin_comparison), &Map.has_key?(check, &1)) do
        unless Map.has_key?(check, "margin") and is_binary(check["margin_unit"]) and
                 byte_size(check["margin_unit"]) in 1..64 and
                 check["margin_comparison"] in ~w(min strict_min max),
               do: raise(ArgumentError, "margins require a value, unit and comparison")

        unless check["margin"] == :null,
          do:
            OrbitalDynamics.MissionAnalysis.Input.number!(
              check["margin"],
              "constraint margin",
              -1.0e30,
              1.0e30
            )
      end
    end)

    ids = Enum.map(checks, & &1["id"])

    if length(ids) != length(Enum.uniq(ids)),
      do: raise(ArgumentError, "duplicate mission check IDs")

    %__MODULE__{checks: checks, metrics: metrics}
  end

  def feasible?(%__MODULE__{checks: checks}), do: Enum.all?(checks, & &1["passed"])
end
