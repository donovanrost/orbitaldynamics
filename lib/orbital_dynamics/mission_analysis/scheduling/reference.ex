defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Reference do
  @moduledoc "JSON adapter with trusted named strategies for reference studies."
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport
  alias OrbitalDynamics.MissionAnalysis.Scheduling.{Policy, Greedy, Reassignment, Replacement}

  def policy!(config) do
    SurfaceSupport.fields!(
      config,
      ~w(strategy max_trials) ++
        Enum.filter(
          ~w(protected_activities retention maintenance work_budget availability command_delivery),
          &Map.has_key?(config, &1)
        ),
      "scheduling search"
    )

    strategy =
      case config["strategy"] do
        "greedy" -> Greedy
        "bounded_reassignment" -> Reassignment
        "bounded_replacement" -> Replacement
        _ -> raise ArgumentError, "unknown scheduling strategy"
      end

    opts = [
      max_trials: config["max_trials"],
      protected_activities: Map.get(config, "protected_activities", []),
      maintenance: Map.get(config, "maintenance"),
      work_budget: Map.get(config, "work_budget"),
      availability: Map.get(config, "availability"),
      command_delivery: Map.get(config, "command_delivery")
    ]

    opts =
      if Map.has_key?(config, "retention") do
        retention =
          case config["retention"] do
            "all_served" -> :all_served
            "protected" -> :protected
            _ -> raise ArgumentError, "unknown request retention mode"
          end

        Keyword.put(opts, :retention, retention)
      else
        opts
      end

    Policy.new!(strategy, opts)
  end
end
