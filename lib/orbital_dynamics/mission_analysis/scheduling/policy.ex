defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Policy do
  @moduledoc "Explicit strategy and whole-schedule trial cap, including the initial greedy evaluation."
  @enforce_keys [:strategy, :max_trials]
  defstruct @enforce_keys ++
              [
                protected_activities: [],
                retention: :all_served,
                maintenance: nil,
                work_budget: nil,
                availability: nil,
                command_delivery: nil
              ]

  def new!(strategy, opts) do
    unless is_atom(strategy) and Code.ensure_loaded?(strategy) and
             function_exported?(strategy, :propose, 4),
           do: raise(ArgumentError, "strategy must be a trusted Scheduling.Strategy module")

    unless Keyword.keyword?(opts) and
             Enum.sort(
               Keyword.keys(opts) --
                 [
                   :protected_activities,
                   :retention,
                   :maintenance,
                   :work_budget,
                   :availability,
                   :command_delivery
                 ]
             ) ==
               [:max_trials] and
             length(Keyword.keys(opts)) == length(Enum.uniq(Keyword.keys(opts))) and
             is_integer(opts[:max_trials]) and opts[:max_trials] in 1..64,
           do:
             raise(
               ArgumentError,
               "explicit max_trials must be 1..64, including the greedy baseline"
             )

    protected =
      OrbitalDynamics.MissionAnalysis.Scheduling.Commitments.normalize!(
        Keyword.get(opts, :protected_activities, [])
      )

    default =
      if strategy == OrbitalDynamics.MissionAnalysis.Scheduling.Replacement,
        do: :protected,
        else: :all_served

    retention = Keyword.get(opts, :retention, default)

    unless retention in [:all_served, :protected],
      do: raise(ArgumentError, "retention must be :all_served or :protected")

    maintenance =
      OrbitalDynamics.MissionAnalysis.Scheduling.Maintenance.validate!(opts[:maintenance])

    if maintenance && maintenance["max_trials"] * opts[:max_trials] > 64,
      do: raise(ArgumentError, "combined maintenance and scheduling trial cap must not exceed 64")

    %__MODULE__{
      strategy: strategy,
      max_trials: opts[:max_trials],
      protected_activities: protected,
      retention: retention,
      maintenance: maintenance,
      work_budget: OrbitalDynamics.MissionAnalysis.Scheduling.Work.validate!(opts[:work_budget]),
      command_delivery:
        OrbitalDynamics.MissionAnalysis.Scheduling.CommandDelivery.validate!(
          opts[:command_delivery]
        ),
      availability:
        OrbitalDynamics.MissionAnalysis.Scheduling.Availability.validate!(opts[:availability])
    }
  end

  def validate!(%__MODULE__{} = p),
    do:
      new!(p.strategy,
        max_trials: p.max_trials,
        protected_activities: p.protected_activities,
        retention: p.retention,
        maintenance: p.maintenance,
        work_budget: p.work_budget,
        command_delivery: p.command_delivery,
        availability: p.availability
      )
end
