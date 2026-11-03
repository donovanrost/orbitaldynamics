defmodule OrbitalDynamics.MissionAnalysis.Opportunity.Policy do
  @moduledoc "Explicit per-pair event-search controls and mission timing margins for schedulable windows."
  alias OrbitalDynamics.MissionAnalysis.Input

  @enforce_keys [
    :max_check_step_s,
    :time_tolerance_s,
    :max_iterations,
    :max_evaluations,
    :entry_margin_s,
    :exit_margin_s
  ]
  defstruct @enforce_keys

  def new!(opts) do
    unless Keyword.keyword?(opts) and Enum.sort(Keyword.keys(opts)) == Enum.sort(@enforce_keys),
      do: raise(ArgumentError, "explicit opportunity search controls and timing margins required")

    step = Input.positive!(opts[:max_check_step_s], "opportunity search step")

    tolerance =
      Input.number!(opts[:time_tolerance_s], "opportunity time tolerance", 0.000001, 1.0e6)

    unless tolerance < step,
      do: raise(ArgumentError, "opportunity tolerance must be below scan step")

    for {key, high} <- [max_iterations: 128, max_evaluations: 100_000] do
      unless is_integer(opts[key]) and opts[key] in 1..high,
        do: raise(ArgumentError, "invalid opportunity #{key}")
    end

    %__MODULE__{
      max_check_step_s: step,
      time_tolerance_s: tolerance,
      max_iterations: opts[:max_iterations],
      max_evaluations: opts[:max_evaluations],
      entry_margin_s: Input.number!(opts[:entry_margin_s], "entry mission margin", 0, 1.0e6),
      exit_margin_s: Input.number!(opts[:exit_margin_s], "exit mission margin", 0, 1.0e6)
    }
  end

  def describe(p), do: Map.from_struct(p) |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)
end
