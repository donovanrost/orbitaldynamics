defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.SnapshotDiffTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Snapshot, Diff}

  defp activity(id, asset, start, value),
    do: %{
      "request_id" => id,
      "asset_id" => asset,
      "starts_at_s" => start,
      "ends_at_s" => start + 10,
      "value" => value
    }

  defp report(activities, requests) do
    selected = MapSet.new(activities, & &1["request_id"])

    %{
      "format" => "mission_analysis.v1",
      "time_system" => %{"epoch_origin" => "J2000", "scale" => "utc"},
      "activities" => activities,
      "requests" =>
        Enum.map(requests, fn {id, v} ->
          scheduled = MapSet.member?(selected, id)

          %{
            "request_id" => id,
            "value" => v,
            "status" => if(scheduled, do: "scheduled", else: "unfulfilled"),
            "reasons" => if(scheduled, do: [], else: ["no_supported_slot"])
          }
        end)
    }
  end

  test "snapshot roundtrip, parent and all source/report values participate in content identity" do
    r = report([activity("r", "a", 10, 3)], [{"r", 3}])
    s = Snapshot.new!(%{"study" => %{"x" => 1}, "mission" => [1, 2]}, r)
    assert s == Snapshot.new!(%{"mission" => [1, 2], "study" => %{"x" => 1}}, r)
    assert s == :json.encode(s) |> IO.iodata_to_binary() |> :json.decode() |> Snapshot.verify!()
    child = Snapshot.new!(s["payload"]["inputs"], r, s["snapshot_id"])
    assert child["snapshot_id"] != s["snapshot_id"]

    for tampered <- [
          put_in(s, ["payload", "inputs", "study", "x"], 2),
          put_in(s, ["payload", "report", "activities", Access.at(0), "asset_id"], "b"),
          Map.put(s, "snapshot_id", "wrong")
        ] do
      assert_raise ArgumentError, ~r/identity mismatch/, fn -> Snapshot.verify!(tampered) end
    end
  end

  test "snapshot loading rejects duplicate keys and oversized input before reading a large body" do
    dir = Path.join(System.tmp_dir!(), "snapshot-test-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    path = Path.join(dir, "snapshot.json")
    File.write!(path, ~s({"snapshot_id":"a","snapshot_id":"b"}))
    assert_raise ArgumentError, ~r/duplicate/, fn -> Snapshot.read!(path) end

    File.open!(path, [:write, :binary], fn file ->
      :file.position(file, 64 * 1024 * 1024)
      :file.write(file, <<0>>)
    end)

    assert_raise ArgumentError, ~r/64 MiB/, fn -> Snapshot.read!(path) end
  end

  test "diff distinguishes additions, removals, moves and exact protected placements" do
    before =
      report(
        [
          activity("keep", "a", 10, 10),
          activity("move", "a", 25, 9),
          activity("drop", "a", 40, 8)
        ],
        [{"keep", 10}, {"move", 9}, {"drop", 8}, {"waiting", 7}]
      )

    after_plan =
      report(
        [
          activity("keep", "a", 10, 10),
          activity("move", "b", 30, 9),
          activity("urgent", "a", 40, 20)
        ],
        [{"keep", 10}, {"move", 9}, {"drop", 8}, {"waiting", 7}, {"urgent", 20}]
      )

    pin = Map.take(hd(before["activities"]), ~w(request_id asset_id starts_at_s ends_at_s))
    d = Diff.compare!(before, after_plan, [pin])
    assert d["counts"] == %{"added" => 1, "removed" => 1, "moved" => 1, "unchanged" => 1}
    assert d["value_delta"] == 12

    assert d["replacement_summary"] == %{
             "removed_request_ids" => ["drop"],
             "newly_served_request_ids" => ["urgent"],
             "causal_pairing" => "not_inferred"
           }

    assert d["new_request_ids"] == ["urgent"]
    assert Enum.find(d["activities"], &(&1["request_id"] == "keep"))["protected"]
    moved = Enum.find(d["activities"], &(&1["request_id"] == "move"))
    assert moved["changed_fields"] == ~w(asset_id starts_at_s ends_at_s)
    assert length(d["unfulfilled_requests"]) == 2
  end

  test "diff never disguises a protected move or compares different time systems" do
    before = report([activity("r", "a", 10, 1)], [{"r", 1}])
    after_plan = report([activity("r", "b", 10, 1)], [{"r", 1}])
    pin = Map.take(hd(before["activities"]), ~w(request_id asset_id starts_at_s ends_at_s))
    assert_raise ArgumentError, ~r/protected/, fn -> Diff.compare!(before, after_plan, [pin]) end

    assert_raise ArgumentError, ~r/time systems/, fn ->
      Diff.compare!(before, put_in(after_plan, ["time_system", "scale"], "tai"))
    end

    malformed = Map.update!(before, "activities", &(&1 ++ &1))
    assert_raise ArgumentError, ~r/duplicate scheduled/, fn -> Snapshot.new!(%{}, malformed) end
  end
end
