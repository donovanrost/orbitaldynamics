defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.StateQuality do
  @moduledoc "Declared observation/prediction provenance, freshness and error-bound policy for common-epoch state updates. No estimation or robust propagation."
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  @kinds ~w(observed synthetic_prediction synthetic_execution)
  @limits ~w(attitude_error_deg rate_error_deg_s battery_error_wh wheel_error_nms)

  def validate_policy!(nil, _, _), do: nil

  def validate_policy!(p, mission, study) do
    unless is_map(p), do: raise(ArgumentError, "state quality policy must be an object")

    S.fields!(
      p,
      ~w(allowed_kinds maximum_measurement_age_s minimum_validity_s assets),
      "state quality policy"
    )

    unless is_list(p["allowed_kinds"]) and p["allowed_kinds"] != [] and
             Enum.all?(p["allowed_kinds"], &(&1 in @kinds)) and
             length(Enum.uniq(p["allowed_kinds"])) == length(p["allowed_kinds"]),
           do: raise(ArgumentError, "explicit unique state-quality kinds required")

    for key <- ~w(maximum_measurement_age_s minimum_validity_s), do: nonnegative!(p[key], key)
    ids = Enum.map(mission["assets"], & &1["id"])

    unless is_map(p["assets"]) and Enum.sort(Map.keys(p["assets"])) == Enum.sort(ids),
      do: raise(ArgumentError, "state quality policy must cover every asset")

    for id <- ids do
      limits = p["assets"][id]
      unless is_map(limits), do: raise(ArgumentError, "asset quality limits must be an object")
      S.fields!(limits, fields(study, id), "state quality limits")
      shape!(limits, study, id)
    end

    p
  end

  def review(u, source) do
    p = source["study"]["state_quality_policy"]
    present = Enum.any?(u["assets"], fn {_, a} -> Map.has_key?(a, "quality") end)

    cond do
      p == nil and not present ->
        nil

      p == nil ->
        result([
          issue(
            "quality_policy_required",
            "state",
            "quality metadata requires an explicit policy"
          )
        ])

      true ->
        validate_policy!(p, source["mission"], source["study"])

        errors =
          Enum.flat_map(u["assets"], fn {id, a} ->
            assess(a["quality"], p["assets"][id], p, u["as_of_s"], source["study"], id)
          end)

        result(errors)
    end
  end

  def stamp(source, id, t, kind, source_id) do
    if source["study"]["state_quality_policy"] do
      limits = source["study"]["state_quality_policy"]["assets"][id]

      packet = %{
        "kind" => kind,
        "source_id" => source_id,
        "state_epoch_s" => t,
        "measurement_epoch_s" => :null,
        "valid_until_s" => t,
        "bounds" => %{
          "attitude_error_deg" => 0,
          "rate_error_deg_s" => 0,
          "battery_error_wh" => Map.new(limits["battery_error_wh"], fn {k, _} -> {k, 0} end),
          "wheel_error_nms" => Map.new(limits["wheel_error_nms"], fn {k, _} -> {k, [0, 0, 0]} end)
        }
      }

      if Map.has_key?(limits, "thermal_error_k"),
        do:
          put_in(
            packet,
            ["bounds", "thermal_error_k"],
            Map.new(limits["thermal_error_k"], fn {id, _} -> {id, 0} end)
          ),
        else: packet
    end
  end

  defp assess(q, limits, p, t, study, id) do
    try do
      S.fields!(
        q,
        ~w(kind source_id state_epoch_s measurement_epoch_s valid_until_s bounds),
        "state quality metadata"
      )

      Input.id!(q["source_id"])
      shape!(q["bounds"], study, id)
      errors = []

      errors =
        errors ++
          check(
            q["kind"] in p["allowed_kinds"],
            "quality_kind",
            id,
            "state source kind is not permitted"
          )

      errors =
        errors ++
          check(
            q["state_epoch_s"] == t,
            "quality_epoch",
            id,
            "state estimate must be at the declared common epoch"
          )

      errors =
        errors ++
          check(
            is_number(q["valid_until_s"]) and q["valid_until_s"] >= t + p["minimum_validity_s"],
            "quality_expired",
            id,
            "state estimate validity does not meet policy"
          )

      errors =
        errors ++
          if q["kind"] == "observed" do
            measured = q["measurement_epoch_s"]

            check(
              is_number(measured) and measured <= t and
                t - measured <= p["maximum_measurement_age_s"],
              "quality_stale_measurement",
              id,
              "measurement epoch is future, missing or older than policy permits"
            )
          else
            check(
              q["kind"] in @kinds and q["measurement_epoch_s"] == :null,
              "quality_source_provenance",
              id,
              "synthetic state must not claim a measured epoch"
            )
          end

      bounds = q["bounds"]

      errors ++
        Enum.flat_map(fields(study, id), fn key ->
          ok =
            case key do
              k when k in ~w(attitude_error_deg rate_error_deg_s) ->
                bounds[k] <= limits[k]

              k when k in ["battery_error_wh", "thermal_error_k"] ->
                Enum.all?(bounds[key], fn {k, v} -> v <= limits[key][k] end)

              "wheel_error_nms" ->
                Enum.all?(bounds[key], fn {k, v} ->
                  Enum.zip_with(v, limits[key][k], &(&1 <= &2)) |> Enum.all?()
                end)
            end

          check(
            ok,
            "quality_error_bound",
            id,
            "declared #{key} exceeds configured acceptance limit"
          )
        end)
    rescue
      _ in [ArgumentError, KeyError, BadMapError, Protocol.UndefinedError, FunctionClauseError] ->
        [issue("quality_metadata", id, "complete valid provenance and error bounds are required")]
    end
  end

  defp shape!(bounds, study, id) do
    S.fields!(bounds, fields(study, id), "state error bounds")
    nonnegative!(bounds["attitude_error_deg"], "attitude error")
    nonnegative!(bounds["rate_error_deg_s"], "rate error")
    models = get_in(study, ["resources", "assets", id]) || []

    for {key, kind} <-
          [{"battery_error_wh", "battery"}, {"wheel_error_nms", "reaction_wheels"}] ++
            if("thermal_error_k" in fields(study, id),
              do: [{"thermal_error_k", "thermal"}],
              else: []
            ) do
      ids = Enum.filter(models, &(&1["model"] == kind)) |> Enum.map(& &1["id"])
      values = bounds[key]

      unless is_map(values) and Enum.sort(Map.keys(values)) == Enum.sort(ids),
        do: raise(ArgumentError, "error bounds require every #{kind} model")

      Enum.each(values, fn {_, value} ->
        if kind != "reaction_wheels",
          do: nonnegative!(value, "battery error"),
          else:
            value
            |> Input.vector!("wheel error")
            |> Tuple.to_list()
            |> Enum.each(&nonnegative!(&1, "wheel error"))
      end)
    end
  end

  defp fields(study, id),
    do:
      @limits ++
        if(
          Enum.any?(
            get_in(study, ["resources", "assets", id]) || [],
            &(&1["model"] == "thermal")
          ), do: ["thermal_error_k"], else: [])

  defp nonnegative!(v, label), do: Input.number!(v, label, 0, 1.0e12)
  defp check(true, _, _, _), do: []
  defp check(false, code, id, message), do: [issue(code, id, message)]
  defp issue(code, id, message), do: %{"code" => code, "asset_id" => id, "message" => message}

  defp result(issues),
    do: %{
      "status" => if(issues == [], do: "supported", else: "rejected"),
      "issues" => issues,
      "scope" =>
        "declared point-estimate quality gate; bounds are not statistical confidence or robust feasibility; source identity is declared, not authenticated"
    }
end
