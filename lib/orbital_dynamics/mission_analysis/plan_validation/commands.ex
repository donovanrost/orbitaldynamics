defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Commands do
  @moduledoc "Independent declared-contact feasibility and synthetic receipt accounting; no allocator calls."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker, as: C

  def snapshot(inputs, report, label) do
    case get_in(inputs, ["study", "scheduling", "command_delivery"]) do
      nil ->
        []

      c ->
        try do
          boundary = inputs["study"]["horizon"]["starts_at_s"]
          evidence = report["scheduling_search"]["command_delivery"]
          rows = evidence["contact_allocation"]["rows"]
          contacts = Map.new(c["contacts"], &{&1["id"], &1})
          allocated = Enum.filter(rows, &(&1["effective_allocation_status"] == "allocated"))
          ids = Enum.map(rows, & &1["contact_id"])
          claims = Enum.flat_map(c["requirements"], & &1["contact_ids"])

          schema =
            c["time_scale"] == inputs["study"]["horizon"]["time_scale"] and
              length(c["contacts"]) <= 128 and length(c["requirements"]) <= 100 and
              length(c["station_calendar"]) <= 128 and
              length(Enum.uniq(ids)) == length(ids) and
              Enum.sort(ids) == Enum.sort(Map.keys(contacts)) and
              length(claims) == length(Enum.uniq(claims)) and
              length(Enum.uniq_by(c["requirements"], & &1["request_id"])) ==
                length(c["requirements"]) and
              Enum.all?(rows, fn row ->
                x = contacts[row["contact_id"]]

                Map.take(
                  row,
                  ~w(scenario_id ground_station_id starts_at_s ends_at_s source_window_id type)
                ) ==
                  Map.take(
                    x,
                    ~w(scenario_id ground_station_id starts_at_s ends_at_s source_window_id type)
                  )
              end) and
              Enum.all?(allocated, fn row ->
                x = contacts[row["contact_id"]]

                x["type"] == "command" and x["starts_at_s"] < x["ends_at_s"] and
                  not Enum.any?(
                    c["station_calendar"],
                    &(&1["ground_station_id"] == x["ground_station_id"] and
                        &1["status"] in ~w(unavailable maintenance) and overlap?(&1, x))
                  )
              end) and
              Enum.with_index(allocated)
              |> Enum.all?(fn {x, n} ->
                Enum.drop(allocated, n + 1)
                |> Enum.all?(fn y ->
                  not overlap?(x, y) or
                    (x["ground_station_id"] != y["ground_station_id"] and
                       x["scenario_id"] != y["scenario_id"])
                end)
              end)

          base =
            C.check(
              schema,
              "command_allocation",
              label,
              "declared contact allocation violates identity, calendar or shared station/spacecraft capacity"
            )

          receipt_ids = Enum.map(c["receipts"], & &1["request_id"])

          receipt_errors =
            C.check(
              length(receipt_ids) == length(Enum.uniq(receipt_ids)),
              "command_receipt",
              label,
              "duplicate receipts"
            ) ++
              Enum.flat_map(c["receipts"], fn receipt ->
                req = Enum.find(c["requirements"], &(&1["request_id"] == receipt["request_id"]))
                x = contacts[receipt["contact_id"]]

                C.check(
                  (req && x &&
                     receipt["kind"] in ~w(observed synthetic_prediction synthetic_execution)) and
                    is_binary(receipt["source_id"]) and
                    Enum.any?(allocated, &(&1["contact_id"] == x["id"])) and
                    receipt["delivered_at_s"] == x["ends_at_s"] and
                    receipt["delivered_at_s"] <= boundary and
                    eligible?(x, req, receipt["asset_id"]),
                  "command_receipt",
                  label,
                  "receipt lacks an eligible contact before the current boundary"
                )
              end)

          busy_errors =
            Enum.flat_map(report["activities"], fn act ->
              C.check(
                not Enum.any?(
                  allocated,
                  &(&1["scenario_id"] == act["asset_id"] and overlap?(&1, act))
                ),
                "command_spacecraft_busy",
                label,
                "service overlaps allocated command contact"
              )
            end)

          base ++
            busy_errors ++
            receipt_errors ++
            Enum.flat_map(report["activities"], fn activity ->
              req = Enum.find(c["requirements"], &(&1["request_id"] == activity["request_id"]))

              if req do
                start =
                  if activity["activity_segment"],
                    do: activity["activity_segment"]["activity_starts_at_s"],
                    else: activity["starts_at_s"]

                ok =
                  Enum.any?(allocated, fn row ->
                    x = contacts[row["contact_id"]]

                    is_number(start) and eligible?(x, req, activity["asset_id"]) and
                      x["ends_at_s"] + req["lead_time_s"] <= start and
                      (x["starts_at_s"] >= boundary or
                         Enum.any?(
                           c["receipts"],
                           &(&1["request_id"] == req["request_id"] and
                               &1["asset_id"] == activity["asset_id"] and
                               &1["contact_id"] == x["id"])
                         ))
                  end)

                C.check(
                  ok,
                  "command_prerequisite",
                  label <> "/" <> activity["request_id"],
                  "activity lacks an eligible command before its deadline/lead time or a required past-contact receipt"
                )
              else
                []
              end
            end)
        rescue
          _ -> [C.issue("command_schema", label, "invalid command delivery evidence")]
        end
    end
  end

  def receipts(parent, u, label) do
    source = parent["payload"]["inputs"]

    case get_in(source, ["study", "scheduling", "command_delivery"]) do
      nil ->
        C.check(
          not Map.has_key?(u, "command_receipts"),
          "command_receipt",
          label,
          "undeclared command receipt policy"
        )

      c ->
        rows =
          parent["payload"]["report"]["scheduling_search"]["command_delivery"][
            "contact_allocation"
          ]["rows"]

        ids =
          rows
          |> Enum.filter(&(&1["effective_allocation_status"] == "allocated"))
          |> Enum.map(& &1["contact_id"])

        old = Map.new(c["receipts"], &{&1["request_id"], &1})

        expected =
          Enum.reduce(parent["payload"]["report"]["activities"], old, fn act, acc ->
            req = Enum.find(c["requirements"], &(&1["request_id"] == act["request_id"]))

            if req && not Map.has_key?(acc, act["request_id"]) do
              x =
                Enum.filter(
                  c["contacts"],
                  &(&1["id"] in ids and eligible?(&1, req, act["asset_id"]) and
                      &1["ends_at_s"] <= u["as_of_s"] and
                      &1["ends_at_s"] + req["lead_time_s"] <= act["starts_at_s"])
                )
                |> Enum.sort_by(&{&1["ends_at_s"], &1["id"]})
                |> List.first()

              if x,
                do:
                  Map.put(acc, act["request_id"], %{
                    "request_id" => act["request_id"],
                    "asset_id" => act["asset_id"],
                    "contact_id" => x["id"],
                    "delivered_at_s" => x["ends_at_s"],
                    "source_id" => "synthetic_declared_contact_execution",
                    "kind" => "synthetic_execution"
                  }),
                else: acc
            else
              acc
            end
          end)
          |> Map.values()
          |> Enum.sort_by(& &1["request_id"])

        C.check(
          u["command_receipts"] == expected,
          "synthetic_command_receipts",
          label,
          "scripted receipts differ from parent-declared allocated command execution"
        )
    end
  end

  defp eligible?(x, r, asset),
    do:
      x["scenario_id"] == asset and x["id"] in r["contact_ids"] and
        x["ends_at_s"] - x["starts_at_s"] >= r["minimum_contact_duration_s"] and
        x["ends_at_s"] <= r["deadline_s"]

  defp overlap?(a, b), do: a["starts_at_s"] < b["ends_at_s"] and b["starts_at_s"] < a["ends_at_s"]
end
