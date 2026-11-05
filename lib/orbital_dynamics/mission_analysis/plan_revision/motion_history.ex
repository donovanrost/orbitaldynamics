defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.MotionHistory do
  @moduledoc "Source-bound execution intervals and reusable future motion; no observation or abort is inferred."
  alias OrbitalDynamics.MissionAnalysis.Attitude.SavedMotion
  @placement ~w(request_id asset_id starts_at_s ends_at_s)

  def records(snapshot) do
    r = snapshot["payload"]["report"]
    s = snapshot["payload"]["inputs"]["study"]

    Map.new(snapshot["payload"]["inputs"]["mission"]["assets"], fn asset ->
      id = asset["id"]

      acquisitions =
        Map.new(
          Enum.filter(
            r["attitude_planning"]["transitions"],
            &(&1["asset_id"] == id and &1["destination_epoch_s"] > &1["source_epoch_s"])
          ),
          fn p ->
            a = Enum.find(r["activities"], &(&1["id"] == p["to_activity_id"]))

            {a["request_id"],
             record(p, get_in(s, ["path_constraints", "assets", id, "transition_mode"]), false)}
          end
        )

      terminal =
        get_in(r, ["attitude_planning", "horizon_coverage", "assets", id, "terminal_motion"])

      terminal =
        if terminal && terminal["destination_epoch_s"] > terminal["source_epoch_s"],
          do: record(terminal, s["horizon"]["terminals"][id]["mode"], false),
          else: :null

      {id, %{"acquisitions" => acquisitions, "terminal" => terminal, "committed" => :null}}
    end)
  end

  defp record(plan, mode, strict),
    do: %{
      "source_plan" =>
        plan
        |> Map.take(~w(source_epoch_s destination_epoch_s status phases))
        |> Map.update!(
          "phases",
          &Enum.filter(&1, fn p -> p["ends_after_s"] > p["starts_after_s"] end)
        ),
      "mode" => mode,
      "starts_at_s" => plan["source_epoch_s"],
      "ends_at_s" => plan["destination_epoch_s"],
      "strict" => strict
    }

  def future(snapshot, t) do
    assets =
      Map.new(records(snapshot), fn {id, c} ->
        acquisitions =
          Enum.flat_map(c["acquisitions"], fn {req, r} ->
            if r["ends_at_s"] > t do
              underway = block_end(r, t) == r["ends_at_s"]

              [
                {req,
                 r
                 |> Map.put("starts_at_s", max(t, r["starts_at_s"]))
                 |> Map.put("strict", underway)}
              ]
            else
              []
            end
          end)
          |> Map.new()

        terminal =
          if is_map(c["terminal"]) and c["terminal"]["ends_at_s"] > t,
            do: Map.put(c["terminal"], "starts_at_s", max(t, c["terminal"]["starts_at_s"])),
            else: :null

        candidates = Map.values(acquisitions) ++ if(is_map(terminal), do: [terminal], else: [])

        committed =
          Enum.find_value(candidates, fn r ->
            if stop = block_end(r, t),
              do:
                r
                |> Map.put("starts_at_s", t)
                |> Map.put("ends_at_s", stop)
                |> Map.put("strict", true)
          end) || :null

        {id, %{"acquisitions" => acquisitions, "terminal" => terminal, "committed" => committed}}
      end)

    %{"source_snapshot_id" => snapshot["snapshot_id"], "role" => "replanning", "assets" => assets}
  end

  def block_end(r, t) do
    p = r["source_plan"]
    origin = p["source_epoch_s"]
    phases = Enum.filter(p["phases"], &(&1["ends_after_s"] > &1["starts_after_s"]))

    current =
      Enum.find_index(
        phases,
        &(origin + &1["starts_after_s"] <= t and t < origin + &1["ends_after_s"])
      )

    if current != nil and Enum.at(phases, current)["kind"] != "hold" and r["starts_at_s"] <= t and
         t < r["ends_at_s"] do
      block = phases |> Enum.drop(current) |> Enum.take_while(&(&1["kind"] != "hold"))
      min(r["ends_at_s"], origin + List.last(block)["ends_after_s"])
    else
      nil
    end
  end

  def pins(snapshot, t) do
    future(snapshot, t)["assets"]
    |> Enum.flat_map(fn {id, c} ->
      for {req, r} <- c["acquisitions"],
          r["strict"],
          do:
            snapshot["payload"]["report"]["activities"]
            |> Enum.find(&(&1["request_id"] == req and &1["asset_id"] == id))
            |> Map.take(@placement)
    end)
  end

  def committed?(snapshot, t),
    do: Enum.any?(future(snapshot, t)["assets"], fn {_, c} -> is_map(c["committed"]) end)

  def replay(snapshot, t, executed, running) do
    all = records(snapshot)
    s = snapshot["payload"]["inputs"]["study"]

    assets =
      Map.new(all, fn {id, c} ->
        acts = Enum.filter(executed, &(&1["asset_id"] == id))

        acquisitions =
          Map.take(c["acquisitions"], Enum.map(acts, & &1["request_id"]))
          |> Enum.filter(fn {_, r} -> r["ends_at_s"] > r["starts_at_s"] end)
          |> Map.new(fn {req, r} -> {req, Map.put(r, "strict", true)} end)

        inside = Enum.find(running, &(&1["asset_id"] == id))
        last = List.last(acts)
        from = if last, do: last["ends_at_s"], else: s["horizon"]["starts_at_s"]

        tail =
          if inside != nil or from == t do
            :null
          else
            r =
              Enum.find_value(c["acquisitions"], fn {_, r} ->
                if r["starts_at_s"] <= from and from < r["ends_at_s"] and t <= r["ends_at_s"],
                  do: r
              end) || c["terminal"]

            unless is_map(r) and r["starts_at_s"] <= from and t <= r["ends_at_s"],
              do: raise(ArgumentError, "saved motion does not cover execution checkpoint")

            r
            |> Map.put("starts_at_s", from)
            |> Map.put("ends_at_s", t)
            |> Map.put("strict", true)
          end

        {id, %{"acquisitions" => acquisitions, "terminal" => tail, "committed" => :null}}
      end)

    %{
      "source_snapshot_id" => snapshot["snapshot_id"],
      "role" => "execution_prefix",
      "assets" => assets
    }
  end

  def terminal(snapshot, id, t) do
    r = snapshot["payload"]["report"]
    s = snapshot["payload"]["inputs"]["study"]

    activity =
      Enum.find(
        r["activities"],
        &(&1["asset_id"] == id and &1["starts_at_s"] < t and t <= &1["ends_at_s"])
      )

    if activity do
      p =
        Enum.find(activity["attitude_profile"], &(&1["epoch_s"] == t)) ||
          raise(
            ArgumentError,
            "execution checkpoint requires an exact saved activity attitude sample"
          )

      Map.merge(Map.take(p, ~w(quaternion_wxyz angular_velocity_inertial_deg_s)), %{
        "strategy" => "activity_boundary",
        "frame" => "eci_j2000",
        "mode" =>
          get_in(s, ["path_constraints", "assets", id, "activity_modes", activity["request_id"]])
      })
    else
      c = records(snapshot)[id]

      plan =
        Enum.find_value(c["acquisitions"], fn {_, r} ->
          if r["starts_at_s"] <= t and t <= r["ends_at_s"], do: r
        end) || c["terminal"]

      unless is_map(plan) and plan["starts_at_s"] <= t and t <= plan["ends_at_s"],
        do: raise(ArgumentError, "no saved motion at checkpoint")

      p = SavedMotion.pose(plan["source_plan"], t)
      # A composed path can carry modes inherited from an earlier checkpoint.
      origin = plan["source_plan"]["source_epoch_s"]

      phase =
        Enum.find(
          plan["source_plan"]["phases"],
          &(origin + &1["starts_after_s"] <= t and t < origin + &1["ends_after_s"])
        ) || List.last(plan["source_plan"]["phases"])

      Map.merge(Map.take(p, ~w(quaternion_wxyz angular_velocity_inertial_deg_s)), %{
        "strategy" => "execution_boundary",
        "frame" => "eci_j2000",
        "mode" => Map.get(phase, "mode_name", plan["mode"])
      })
    end
  end

  def validate_source!(source) do
    if history = source["study"]["saved_motion"] do
      unless is_map(history) and
               Enum.sort(Map.keys(history)) == ~w(assets role source_snapshot_id) and
               history["role"] in ~w(replanning execution_prefix) and
               is_binary(history["source_snapshot_id"]) and
               Regex.match?(
                 ~r/\Amission_plan_snapshot:[0-9a-f]{64}\z/,
                 history["source_snapshot_id"]
               ),
             do: raise(ArgumentError, "invalid saved motion source")

      ids = Enum.map(source["mission"]["assets"], & &1["id"])

      unless Enum.sort(Map.keys(history["assets"])) == Enum.sort(ids),
        do: raise(ArgumentError, "saved motion must cover exactly the source assets")

      Enum.each(history["assets"], fn {_, c} -> SavedMotion.validate!(c) end)

      if history["role"] == "replanning" do
        u = get_in(source, ["execution", "last_update"])

        unless is_map(u) and u["motion_source_snapshot_id"] == history["source_snapshot_id"] and
                 u["as_of_s"] == source["study"]["horizon"]["starts_at_s"],
               do:
                 raise(
                   ArgumentError,
                   "saved motion does not match the confirmed execution boundary"
                 )
      end
    end

    source
  end
end
