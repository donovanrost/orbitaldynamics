# Phase times/accelerations are production outputs, not an independent duration oracle.
alias OrbitalDynamics.MissionAnalysis.Attitude.Motion
[directory] = System.argv()

read = fn path ->
  [header | rows] = File.read!(path) |> String.split("\n", trim: true)
  keys = String.split(header, ",")
  Enum.map(rows, fn row -> Enum.zip(keys, String.split(row, ",")) |> Map.new() end)
end

number = fn row, key ->
  {v, ""} = Float.parse(row[key])
  v
end

q = fn row, prefix -> Enum.map(~w(w x y z), &number.(row, prefix <> &1)) end
vector = fn row, prefix -> Enum.map(~w(x y z), &number.(row, prefix <> &1)) end
rows = read.(Path.join(directory, "motion-input.csv"))

output =
  Enum.flat_map(rows, fn row ->
    source = %{
      "epoch_s" => 0,
      "quaternion_wxyz" => q.(row, "source_"),
      "angular_velocity_inertial_deg_s" => vector.(row, "source_rate_")
    }

    target = %{
      "epoch_s" => number.(row, "gap_s"),
      "quaternion_wxyz" => q.(row, "target_"),
      "angular_velocity_inertial_deg_s" => vector.(row, "target_rate_")
    }

    limits = %{
      max_rate_deg_s: number.(row, "max_rate_deg_s"),
      max_accel_deg_s2: number.(row, "max_accel_deg_s2"),
      settling_s: number.(row, "settling_s")
    }

    case Motion.transition(source, target, limits) do
      {:ok, plan} ->
        Enum.with_index(plan["phases"], fn p, i ->
          [
            row["id"],
            i,
            p["starts_after_s"],
            p["ends_after_s"] | p["angular_acceleration_inertial_deg_s2"]
          ]
          |> Enum.join(",")
        end)

      {:infeasible, _} ->
        []
    end
  end)

File.write!(
  Path.join(directory, "phase-input.csv"),
  "id,index,starts_s,ends_s,ax_deg_s2,ay_deg_s2,az_deg_s2\n" <> Enum.join(output, "\n") <> "\n"
)
