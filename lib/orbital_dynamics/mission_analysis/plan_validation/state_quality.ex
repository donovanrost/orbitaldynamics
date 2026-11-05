defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.StateQuality do
  @moduledoc "Independent saved-state quality policy checks. Does not invoke producer validation or authenticate observations."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker, as: C
  @fields ~w(attitude_error_deg rate_error_deg_s battery_error_wh wheel_error_nms)
  @kinds ~w(observed synthetic_prediction synthetic_execution)
  def check(i, label) do
    try do
      p = i["study"]["state_quality_policy"]
      update = get_in(i, ["execution", "last_update"])

      present =
        is_map(update) and
          Enum.any?(update["assets"] || %{}, fn {_, a} ->
            is_map(a) and Map.has_key?(a, "quality")
          end)

      cond do
        p == nil ->
          C.check(
            not present,
            "state_quality_policy",
            label,
            "quality metadata has no declared policy"
          )

        true ->
          require!(
            is_map(p) and
              Enum.sort(Map.keys(p)) ==
                ~w(allowed_kinds assets maximum_measurement_age_s minimum_validity_s),
            "invalid quality policy fields"
          )

          require!(
            is_list(p["allowed_kinds"]) and p["allowed_kinds"] != [] and
              Enum.all?(p["allowed_kinds"], &(&1 in @kinds)) and
              length(Enum.uniq(p["allowed_kinds"])) == length(p["allowed_kinds"]),
            "invalid allowed quality kinds"
          )

          require!(
            nonnegative?(p["maximum_measurement_age_s"]) and nonnegative?(p["minimum_validity_s"]),
            "invalid freshness limits"
          )

          ids = Enum.map(i["mission"]["assets"], & &1["id"])

          require!(
            is_map(p["assets"]) and Enum.sort(Map.keys(p["assets"])) == Enum.sort(ids),
            "quality policy must cover all assets"
          )

          Enum.flat_map(ids, fn id ->
            limit = p["assets"][id]
            shape!(limit, i, id)

            if update == nil do
              []
            else
              q = get_in(update, ["assets", id, "quality"])

              require!(
                is_map(q) and
                  Enum.sort(Map.keys(q)) ==
                    ~w(bounds kind measurement_epoch_s source_id state_epoch_s valid_until_s),
                "complete quality metadata required"
              )

              require!(
                is_binary(q["source_id"]) and byte_size(q["source_id"]) <= 256 and
                  Regex.match?(~r/\A[A-Za-z0-9][A-Za-z0-9._:@-]*\z/, q["source_id"]),
                "invalid quality source identity"
              )

              shape!(q["bounds"], i, id)
              t = update["as_of_s"]
              measured = q["measurement_epoch_s"]

              fresh =
                if q["kind"] == "observed",
                  do:
                    is_number(measured) and measured <= t and
                      t - measured <= p["maximum_measurement_age_s"],
                  else: measured == :null and q["kind"] in @kinds

              C.check(
                q["kind"] in p["allowed_kinds"] and q["state_epoch_s"] == t and
                  is_number(q["valid_until_s"]) and
                  q["valid_until_s"] >= t + p["minimum_validity_s"] and fresh,
                "state_quality_freshness",
                label <> "/" <> id,
                "source kind, epoch, freshness or validity violates quality policy"
              ) ++
                Enum.flat_map(fields(i, id), fn field ->
                  b = q["bounds"][field]
                  max = limit[field]

                  within =
                    case field do
                      k when k in ~w(attitude_error_deg rate_error_deg_s) ->
                        b <= max

                      k when k in ["battery_error_wh", "thermal_error_k"] ->
                        Enum.all?(b, fn {key, v} -> v <= max[key] end)

                      "wheel_error_nms" ->
                        Enum.all?(b, fn {key, v} ->
                          Enum.zip_with(v, max[key], &(&1 <= &2)) |> Enum.all?()
                        end)
                    end

                  C.check(
                    within,
                    "state_quality_error_bound",
                    label <> "/" <> id,
                    "declared error bound exceeds policy: " <> field
                  )
                end)
            end
          end)
      end
    rescue
      e in [
        ArgumentError,
        KeyError,
        BadMapError,
        ArithmeticError,
        Protocol.UndefinedError,
        FunctionClauseError
      ] ->
        [C.issue("state_quality_schema", label, Exception.message(e))]
    end
  end

  defp shape!(bounds, i, id) do
    require!(
      is_map(bounds) and Enum.sort(Map.keys(bounds)) == Enum.sort(fields(i, id)),
      "complete state error bounds required"
    )

    require!(
      nonnegative?(bounds["attitude_error_deg"]) and nonnegative?(bounds["rate_error_deg_s"]),
      "invalid attitude/rate bounds"
    )

    models = get_in(i, ["study", "resources", "assets", id]) || []

    for {field, kind} <-
          [{"battery_error_wh", "battery"}, {"wheel_error_nms", "reaction_wheels"}] ++
            if("thermal_error_k" in fields(i, id), do: [{"thermal_error_k", "thermal"}], else: []) do
      ids = Enum.filter(models, &(&1["model"] == kind)) |> Enum.map(& &1["id"])
      values = bounds[field]

      require!(
        is_map(values) and Enum.sort(Map.keys(values)) == Enum.sort(ids),
        "resource error bounds do not cover configured model IDs"
      )

      require!(
        Enum.all?(values, fn {_, v} ->
          if kind != "reaction_wheels",
            do: nonnegative?(v),
            else: is_list(v) and length(v) == 3 and Enum.all?(v, &nonnegative?/1)
        end),
        "invalid resource error bound"
      )
    end
  end

  defp fields(i, id),
    do:
      @fields ++
        if(
          Enum.any?(
            get_in(i, ["study", "resources", "assets", id]) || [],
            &(&1["model"] == "thermal")
          ), do: ["thermal_error_k"], else: [])

  defp nonnegative?(v), do: is_number(v) and v >= 0 and v <= 1.0e12
  defp require!(true, _), do: :ok
  defp require!(false, message), do: raise(ArgumentError, message)
end
