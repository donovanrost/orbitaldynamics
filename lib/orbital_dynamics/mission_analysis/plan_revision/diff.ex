defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.Diff do
  @moduledoc "Request-identity plan diff; additions/removals are not inferred causal replacement pairs."
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Commitments
  @placement ~w(request_id asset_id starts_at_s ends_at_s)

  def compare!(before, after_plan, protected \\ []) do
    Snapshot.validate_report!(before)
    Snapshot.validate_report!(after_plan)

    unless before["time_system"] == after_plan["time_system"],
      do: raise(ArgumentError, "cannot diff different time systems")

    protected = Commitments.normalize!(protected)

    unless Commitments.intact?(before["activities"], protected) and
             Commitments.intact?(after_plan["activities"], protected),
           do: raise(ArgumentError, "revised plan changed a protected placement")

    a = Map.new(before["activities"], &{&1["request_id"], &1})
    b = Map.new(after_plan["activities"], &{&1["request_id"], &1})
    protected_ids = MapSet.new(protected, & &1["request_id"])

    rows =
      for id <- Enum.sort(Enum.uniq(Map.keys(a) ++ Map.keys(b))) do
        old = a[id]
        new = b[id]
        changed = if old && new, do: Enum.filter(tl(@placement), &(old[&1] != new[&1])), else: []

        kind =
          cond do
            old == nil -> "added"
            new == nil -> "removed"
            changed != [] -> "moved"
            true -> "unchanged"
          end

        request = Enum.find(after_plan["requests"], &(&1["request_id"] == id))

        %{
          "request_id" => id,
          "change" => kind,
          "changed_fields" => changed,
          "protected" => MapSet.member?(protected_ids, id),
          "before" => if(old, do: Map.take(old, @placement ++ ["value"]), else: :null),
          "after" => if(new, do: Map.take(new, @placement ++ ["value"]), else: :null),
          "revised_request_status" => if(request, do: request["status"], else: "absent"),
          "revised_unfulfilled_reasons" =>
            if(request && request["status"] != "scheduled", do: request["reasons"], else: [])
        }
      end

    previous_ids = MapSet.new(before["requests"], & &1["request_id"])
    value_before = Enum.sum(Enum.map(before["activities"], & &1["value"]))
    value_after = Enum.sum(Enum.map(after_plan["activities"], & &1["value"]))

    counts =
      Map.new(~w(added removed moved unchanged), fn kind ->
        {kind, Enum.count(rows, &(&1["change"] == kind))}
      end)

    %{
      "activities" => rows,
      "counts" => counts,
      "baseline_value" => value_before,
      "revised_value" => value_after,
      "value_delta" => value_after - value_before,
      "new_request_ids" =>
        for(
          r <- after_plan["requests"],
          not MapSet.member?(previous_ids, r["request_id"]),
          do: r["request_id"]
        )
        |> Enum.sort(),
      "unfulfilled_requests" =>
        after_plan["requests"]
        |> Enum.filter(&(&1["status"] != "scheduled"))
        |> Enum.map(&Map.take(&1, ~w(request_id value reasons scheduling_summary))),
      "replacement_summary" => %{
        "removed_request_ids" => for(r <- rows, r["change"] == "removed", do: r["request_id"]),
        "newly_served_request_ids" => for(r <- rows, r["change"] == "added", do: r["request_id"]),
        "causal_pairing" => "not_inferred"
      }
    }
  end
end
