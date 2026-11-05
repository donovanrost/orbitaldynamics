defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.ExecutionCheckpoint do
  @moduledoc "Independent checkpoint envelope, parent-derived state and retry-control checks; no producer acceptance or planning helpers."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Continuations, StateQuality}
  alias Checker, as: C

  def check(cp, parent, u, label) do
    try do
      p = cp["payload"]

      expected =
        Continuations.advance_inputs(parent["payload"]["inputs"], parent, u)
        |> Map.delete("execution_checkpoint_id")

      digest = C.digest(p)

      basic =
        Enum.sort(Map.keys(cp)) == ~w(checkpoint_id content_sha256 payload) and
          Enum.sort(Map.keys(p)) ==
            ~w(canonicalization format inputs parent_snapshot_id state_update) and
          p["format"] == "mission_execution_checkpoint.v1" and
          p["canonicalization"] == "sorted_json_keys.v1" and
          p["parent_snapshot_id"] == parent["snapshot_id"] and
          p["state_update"] == u and cp["content_sha256"] == digest and
          cp["checkpoint_id"] == "mission_execution_checkpoint:" <> digest and
          IO.iodata_length(:json.encode(cp)) <= 8 * 1024 * 1024

      h = parent["payload"]["inputs"]["study"]["horizon"]

      timing =
        u["expected_baseline_id"] == parent["snapshot_id"] and u["time_scale"] == "utc" and
          u["frame"] == "eci_j2000" and is_number(u["as_of_s"]) and
          h["starts_at_s"] < u["as_of_s"] and u["as_of_s"] < h["ends_at_s"]

      assets = parent["payload"]["inputs"]["mission"]["assets"]

      identities =
        is_map(u["assets"]) and
          Enum.sort(Map.keys(u["assets"])) == Enum.sort(Enum.map(assets, & &1["id"]))

      required =
        ~w(revision_id expected_baseline_id source_id as_of_s time_scale frame assets completed_request_ids not_executed_request_ids protect_request_ids scheduling)

      optional =
        ~w(in_progress_request_ids horizon_extension command_receipts motion_source_snapshot_id)

      shape = required -- Map.keys(u) == [] and Map.keys(u) -- (required ++ optional) == []

      lists =
        Enum.all?(~w(completed_request_ids not_executed_request_ids protect_request_ids), fn k ->
          is_list(u[k]) and length(u[k]) <= 100 and length(Enum.uniq(u[k])) == length(u[k])
        end)

      running = Map.get(u, "in_progress_request_ids", [])
      acts = parent["payload"]["report"]["activities"]
      ended = for a <- acts, a["ends_at_s"] <= u["as_of_s"], do: a["request_id"]

      active =
        for a <- acts,
            a["starts_at_s"] < u["as_of_s"] and u["as_of_s"] < a["ends_at_s"],
            do: a["request_id"]

      declared = u["completed_request_ids"] ++ u["not_executed_request_ids"]

      outcomes =
        lists and length(Enum.uniq(declared)) == length(declared) and
          Enum.sort(declared) == Enum.sort(ended) and Enum.sort(running) == Enum.sort(active) and
          Enum.all?(u["protect_request_ids"], fn id ->
            Enum.any?(acts, &(&1["request_id"] == id and &1["starts_at_s"] >= u["as_of_s"]))
          end)

      source_motion =
        OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory.future(parent, u["as_of_s"])[
          "assets"
        ]

      motion_required = Enum.any?(source_motion, fn {_, c} -> is_map(c["committed"]) end)

      confirmation =
        (not Map.has_key?(u, "motion_source_snapshot_id") or
           u["motion_source_snapshot_id"] == parent["snapshot_id"]) and
          (not motion_required or u["motion_source_snapshot_id"] == parent["snapshot_id"])

      issues =
        C.check(
          basic and timing and identities,
          "execution_checkpoint_identity",
          label,
          "checkpoint envelope, content, update or parent identity differs"
        ) ++
          C.check(
            shape and outcomes and confirmation,
            "execution_checkpoint_outcomes",
            label,
            "checkpoint has invalid update fields, incomplete outcomes or unconfirmed motion"
          ) ++
          C.check(
            normalized(p["inputs"]) == normalized(expected),
            "execution_checkpoint_state",
            label,
            "checkpoint state/history differs from independent parent reconstruction"
          ) ++ StateQuality.check(p["inputs"], label)

      # A checkpoint accepts finite declared state, including a limit violation; never a budget refund.
      source = parent["payload"]["inputs"]
      selected = Map.new(parent["payload"]["report"]["activities"], &{&1["request_id"], &1})
      spent = u["completed_request_ids"] ++ Map.get(u, "in_progress_request_ids", [])

      issues =
        issues ++
          Enum.flat_map(source["mission"]["assets"], fn asset ->
            a = u["assets"][asset["id"]]

            maximum =
              Enum.reduce(spent, asset["resource_budgets"], fn id, b ->
                act = selected[id]

                if act && act["asset_id"] == asset["id"],
                  do:
                    Enum.reduce(act["resource_costs"], b, fn {k, v}, b ->
                      if Map.has_key?(b, k), do: Map.update!(b, k, &(&1 - v)), else: b
                    end),
                  else: b
              end)

            models = get_in(source, ["study", "resources", "assets", asset["id"]]) || []

            fields =
              ~w(quaternion_wxyz angular_velocity_inertial_deg_s battery_energy_wh resource_budgets) ++
                if(Enum.any?(models, &(&1["model"] == "reaction_wheels")),
                  do: ["wheel_momentum_nms"],
                  else: []
                ) ++
                if(Enum.any?(models, &(&1["model"] == "thermal")),
                  do: ["thermal_temperature_k"],
                  else: []
                ) ++ if(Map.has_key?(a, "quality"), do: ["quality"], else: [])

            state_valid =
              Enum.sort(Map.keys(a)) == Enum.sort(fields) and
                vector?(a["quaternion_wxyz"], 4) and
                abs(Enum.sum(Enum.map(a["quaternion_wxyz"], &(&1 * &1))) - 1) <= 1.0e-6 and
                vector?(a["angular_velocity_inertial_deg_s"], 3) and
                resource_map?(a["battery_energy_wh"], models, "battery", fn x, c ->
                  is_number(x) and is_number(c["capacity_wh"]) and x >= 0 and
                    x <= c["capacity_wh"]
                end) and
                resource_map?(
                  Map.get(a, "wheel_momentum_nms", %{}),
                  models,
                  "reaction_wheels",
                  fn x, _ -> vector?(x, 3) end
                ) and
                resource_map?(Map.get(a, "thermal_temperature_k", %{}), models, "thermal", fn x,
                                                                                              _ ->
                  is_number(x) and x >= 0.000001 and x <= 1.0e12
                end)

            valid =
              is_map(a["resource_budgets"]) and
                Enum.sort(Map.keys(a["resource_budgets"])) == Enum.sort(Map.keys(maximum)) and
                Enum.all?(a["resource_budgets"], fn {k, v} ->
                  is_number(v) and v >= 0 and v <= maximum[k]
                end)

            C.check(
              state_valid,
              "execution_checkpoint_state_shape",
              label,
              "checkpoint is missing finite complete physical state"
            ) ++
              C.check(
                valid,
                "execution_checkpoint_budget",
                label,
                "accepted checkpoint increases or refunds non-replenishing budget"
              )
          end)

      {issues, expected}
    rescue
      e in [
        ArgumentError,
        KeyError,
        BadMapError,
        FunctionClauseError,
        ArithmeticError,
        Protocol.UndefinedError
      ] ->
        {[C.issue("execution_checkpoint_schema", label, Exception.message(e))], nil}
    end
  end

  def attempt(inputs, cp, attempt) do
    require!(
      is_map(attempt) and Enum.sort(Map.keys(attempt)) == ~w(attempt_id scheduling),
      "planning attempt fields differ"
    )

    c = attempt["scheduling"]

    require!(
      is_binary(attempt["attempt_id"]) and is_map(c) and
        Map.keys(c) -- ~w(strategy max_trials work_budget) == [],
      "attempt changes fields outside algorithm controls"
    )

    require!(
      c == %{} or
        (c["strategy"] in ~w(greedy bounded_reassignment bounded_replacement) and
           is_integer(c["max_trials"]) and c["max_trials"] in 1..64),
      "invalid attempt strategy/trial controls"
    )

    if Map.has_key?(c, "work_budget") do
      b = c["work_budget"]

      require!(
        is_map(b) and Map.keys(b) == ["max_evaluations"] and is_integer(b["max_evaluations"]) and
          b["max_evaluations"] in 1..100_000_000,
        "invalid retry budget"
      )
    end

    inputs
    |> Map.put("execution_checkpoint_id", cp["checkpoint_id"])
    |> update_in(["study", "scheduling"], &Map.merge(&1, c))
  end

  defp vector?(x, n),
    do: is_list(x) and length(x) == n and Enum.all?(x, &(is_number(&1) and abs(&1) <= 1.0e15))

  defp resource_map?(values, models, kind, valid) do
    selected = Enum.filter(models, &(&1["model"] == kind))

    is_map(values) and Enum.sort(Map.keys(values)) == Enum.sort(Enum.map(selected, & &1["id"])) and
      Enum.all?(selected, fn model -> valid.(values[model["id"]], model["configuration"]) end)
  end

  defp normalized(i),
    do:
      update_in(
        i,
        ["study", "scheduling", "protected_activities"],
        &Enum.sort_by(&1 || [], fn r -> r["request_id"] end)
      )

  defp require!(true, _), do: :ok
  defp require!(false, message), do: raise(ArgumentError, message)
end
