defmodule OrbitalDynamics.Study do
  @moduledoc """
  Reproducible collection of scenarios and model choices.

  A study is the manifest-level object for batch mission analysis. It records
  which scenarios should run, which propagator backend should evaluate them,
  what outputs are requested, and which seeds or metadata are needed to
  reproduce the run.
  """

  alias OrbitalDynamics.{Propagators.TwoBody, Scenario}

  @enforce_keys [
    :id,
    :scenarios,
    :propagator,
    :propagator_opts,
    :outputs,
    :seed_manifest,
    :metadata
  ]
  defstruct [:id, :scenarios, :propagator, :propagator_opts, :outputs, :seed_manifest, :metadata]

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          scenarios: [Scenario.t()],
          propagator: module(),
          propagator_opts: keyword(),
          outputs: [atom()],
          seed_manifest: map(),
          metadata: map()
        }

  @doc """
  Creates a reproducible study manifest.
  """
  def new!(id, scenarios, opts \\ []) do
    propagator = Keyword.get(opts, :propagator, TwoBody)
    propagator_opts = Keyword.get(opts, :propagator_opts, [])
    outputs = Keyword.get(opts, :outputs, [:trajectories])
    seed_manifest = Keyword.get(opts, :seed_manifest, %{})
    metadata = Keyword.get(opts, :metadata, %{})

    cond do
      id in [nil, ""] ->
        raise ArgumentError, "study id is required"

      not valid_scenarios?(scenarios) ->
        raise ArgumentError,
              "scenarios must be a non-empty list of OrbitalDynamics.Scenario structs"

      not unique_scenario_ids?(scenarios) ->
        raise ArgumentError, "scenario ids must be unique within a study"

      not is_atom(propagator) ->
        raise ArgumentError, "propagator must be a module atom"

      not Keyword.keyword?(propagator_opts) ->
        raise ArgumentError, "propagator_opts must be a keyword list"

      not valid_outputs?(outputs) ->
        raise ArgumentError, "outputs must be a non-empty list of atoms"

      not is_map(seed_manifest) ->
        raise ArgumentError, "seed_manifest must be a map"

      not is_map(metadata) ->
        raise ArgumentError, "metadata must be a map"

      true ->
        %__MODULE__{
          id: id,
          scenarios: scenarios,
          propagator: propagator,
          propagator_opts: propagator_opts,
          outputs: outputs,
          seed_manifest: seed_manifest,
          metadata: metadata
        }
    end
  end

  defp valid_scenarios?(scenarios) when is_list(scenarios) and scenarios != [] do
    Enum.all?(scenarios, &match?(%Scenario{}, &1))
  end

  defp valid_scenarios?(_scenarios), do: false

  defp unique_scenario_ids?(scenarios) do
    scenario_ids = Enum.map(scenarios, & &1.id)
    Enum.uniq(scenario_ids) == scenario_ids
  end

  defp valid_outputs?(outputs) when is_list(outputs) and outputs != [] do
    Enum.all?(outputs, &is_atom/1)
  end

  defp valid_outputs?(_outputs), do: false
end
