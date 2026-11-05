defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Coverage do
  @moduledoc "Independent saved-checkpoint structure and overlap comparisons; no trajectory propagation."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker, as: C

  def snapshot(i, r, label) do
    if i["study"]["rolling_horizon"] do
      try do
        m = i["mission"]
        s = i["study"]
        policy = s["rolling_horizon"]
        e = r["trajectory_coverage"]
        step = policy["sample_step_s"]
        n = round(m["duration_s"] / step)
        times = Enum.map(0..n, &(m["epoch_s"] + &1 * step))

        recipe = %{
          "epoch_s" => m["epoch_s"],
          "solar_year_s" => m["solar_year_s"],
          "resolution_level" => s["resolution_level"],
          "assets" =>
            Enum.map(
              m["assets"],
              &Map.take(
                &1,
                ~w(id altitude_km local_time_ascending_node_h initial_argument_of_latitude_deg dry_mass_kg)
              )
            )
        }

        good =
          e["provider"] == "reference_j2" and policy["provider"] == "reference_j2" and
            e["frame"] == "eci_j2000" and e["time_scale"] == "utc" and
            is_integer(policy["max_samples_per_asset"]) and
            policy["max_samples_per_asset"] in 2..512 and
            n >= 1 and n + 1 <= policy["max_samples_per_asset"] and n * step == m["duration_s"] and
            e["starts_at_s"] == m["epoch_s"] and e["ends_at_s"] == m["epoch_s"] + m["duration_s"] and
            e["sample_step_s"] == step and e["recipe_sha256"] == C.digest(recipe) and
            s["horizon"]["starts_at_s"] >= m["epoch_s"] and
            s["horizon"]["ends_at_s"] + 2 * s["attitude"]["derivative_step_s"] <= e["ends_at_s"] and
            Enum.sort(Map.keys(e["assets"])) == Enum.sort(Enum.map(m["assets"], & &1["id"])) and
            Enum.map(e["environment_samples"], & &1["epoch_s"]) == times and
            e["environment_identity"]["coverage"]["starts_at_s"] <= hd(times) and
            e["environment_identity"]["coverage"]["ends_at_s"] >= List.last(times) and
            Enum.all?(
              e["environment_samples"],
              &(vector?(&1["sun_direction"]) and is_number(&1["rotation_angle_rad"]))
            ) and
            Enum.all?(e["assets"], fn {_, rows} ->
              Enum.map(rows, & &1["epoch_s"]) == times and
                Enum.all?(rows, &(vector?(&1["position_km"]) and vector?(&1["velocity_km_s"])))
            end)

        C.check(
          good,
          "trajectory_coverage",
          label,
          "saved checkpoint grid, recipe, frame or explicit coverage is inconsistent"
        )
      rescue
        _ -> [C.issue("trajectory_coverage", label, "invalid coverage checkpoint schema")]
      end
    else
      C.check(
        not Map.has_key?(r, "trajectory_coverage"),
        "trajectory_coverage",
        label,
        "coverage evidence has no declared provider policy"
      )
    end
  end

  def overlap(parent, child, label) do
    a = parent["payload"]["report"]["trajectory_coverage"]
    b = child["payload"]["report"]["trajectory_coverage"]

    try do
      good =
        is_map(a) and is_map(b) and a["ends_at_s"] <= b["ends_at_s"] and
          Map.take(
            a,
            ~w(provider frame time_scale recipe_sha256 environment_identity sample_step_s starts_at_s)
          ) ==
            Map.take(
              b,
              ~w(provider frame time_scale recipe_sha256 environment_identity sample_step_s starts_at_s)
            ) and
          Enum.sort(Map.keys(a["assets"])) == Enum.sort(Map.keys(b["assets"])) and
          Enum.take(b["environment_samples"], length(a["environment_samples"])) ==
            a["environment_samples"] and
          Enum.all?(a["assets"], fn {id, rows} ->
            other = Map.new(b["assets"][id], &{&1["epoch_s"], &1})

            Enum.all?(rows, fn row ->
              x = other[row["epoch_s"]]

              close?(row["position_km"], x["position_km"], 1.0e-8) and
                close?(row["velocity_km_s"], x["velocity_km_s"], 1.0e-11)
            end)
          end)

      C.check(
        good,
        "trajectory_overlap",
        label,
        "extension changed saved trajectory/environment checkpoints or identity"
      )
    rescue
      _ -> [C.issue("trajectory_overlap", label, "missing or malformed parent/child checkpoints")]
    end
  end

  def extend(inputs, nil), do: inputs

  def extend(inputs, e) do
    study =
      Enum.reduce(e["add_requests"], inputs["study"], fn a, s ->
        Enum.reduce(a["activity_modes"], s, fn {id, mode}, acc ->
          put_in(
            acc,
            ["path_constraints", "assets", id, "activity_modes", a["request"]["id"]],
            mode
          )
        end)
      end)

    mission =
      inputs["mission"]
      |> Map.update!("requests", &(&1 ++ Enum.map(e["add_requests"], fn a -> a["request"] end)))
      |> Map.put("duration_s", e["coverage_ends_at_s"] - inputs["mission"]["epoch_s"])

    Map.merge(inputs, %{
      "mission" => mission,
      "study" => put_in(study, ["horizon", "ends_at_s"], e["ends_at_s"])
    })
  end

  defp vector?(v), do: is_list(v) and length(v) == 3 and Enum.all?(v, &is_number/1)

  defp close?(a, b, t),
    do: vector?(a) and vector?(b) and Enum.zip_with(a, b, &(abs(&1 - &2) <= t)) |> Enum.all?()
end
