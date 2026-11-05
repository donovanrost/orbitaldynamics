defmodule OrbitalDynamics.MissionAnalysis.AssignmentQualityCases do
  @moduledoc """
  Tiny exact assignment checks against the production static greedy scheduler.
  Every request occupies the entire single slot and costs one token. Exhaustive
  enumeration is exact only for these fixtures, not for continuous attitude or
  battery-constrained mission planning.
  """
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory, MissionAnalysis}
  alias OrbitalDynamics.MissionAnalysis.{Asset, Evaluation, Request}

  defmodule Model do
    @moduledoc false
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "synthetic_assignment_slot"}
    def prepare(request, config, _), do: {:ok, request.id in config["allowed"], %{}}

    def evaluate(_, _, allowed),
      do: {:ok, Evaluation.new!([%{"id" => "assignment_allowed", "passed" => allowed}], %{})}
  end

  def run!(scheduling \\ nil) do
    Enum.map(
      [
        {"independent", [{"a", ["high"]}, {"b", ["low"]}], [{"high", 10}, {"low", 9}]},
        {"flexible_request_trap", [{"a", ["high", "low"]}, {"b", ["high"]}],
         [{"high", 10}, {"low", 9}]},
        {"single_slot_contention", [{"a", ["high", "low"]}], [{"high", 10}, {"low", 9}]}
      ],
      fn {id, slots, values} ->
        frame = Frame.new!(:assignment_inertial, :synthetic, :synthetic)

        states =
          Enum.map(
            [0, 10],
            &StateVector.new!({2000, 0, 0}, {0, 1, 0}, Epoch.new!(&1, :tai), frame)
          )

        trajectory = %Trajectory{scenario_id: id, states: states, assumptions: %{}}

        assets =
          Enum.map(slots, fn {name, allowed} ->
            Asset.new!(name, trajectory, %{Model => %{"allowed" => allowed}}, %{"tokens" => 1})
          end)

        requests =
          Enum.map(values, fn {name, value} ->
            Request.new!(name, Model, nil,
              activity_type: "slot",
              starts_at_s: 0,
              ends_at_s: 10,
              duration_s: 10,
              time_scale: :tai,
              value: value,
              parameters: %{},
              resource_costs: %{"tokens" => 1}
            )
          end)

        {:ok, report} =
          MissionAnalysis.run(
            assets,
            requests,
            %{},
            [max_sample_gap_s: 10, asset_separation_s: 0] ++
              if(scheduling, do: [scheduling: scheduling], else: [])
          )

        greedy = Enum.sum(Enum.map(report["activities"], & &1["value"]))
        {optimal, assignment} = best(values, slots)

        %{
          "id" => id,
          if(scheduling, do: "planner_value", else: "greedy_value") => greedy,
          "optimal_value" => optimal,
          "absolute_gap" => optimal - greedy,
          "value_ratio" => greedy / optimal,
          "optimal_assignment" => assignment,
          "scope" => "exact_single_slot_assignment_only_no_attitude_or_battery"
        }
      end
    )
  end

  defp best([], _), do: {0, []}

  defp best([{request, value} | rest], slots) do
    choices =
      for {asset, allowed} <- slots, request in allowed do
        {tail_value, tail} = best(rest, Enum.reject(slots, fn {id, _} -> id == asset end))
        {value + tail_value, [%{"asset_id" => asset, "request_id" => request} | tail]}
      end

    Enum.max_by([best(rest, slots) | choices], &elem(&1, 0))
  end
end
