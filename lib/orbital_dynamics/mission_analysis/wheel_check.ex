defmodule OrbitalDynamics.MissionAnalysis.WheelCheck do
  @moduledoc "Content-bound comparison of production wheel dynamics with separately integrated body-frame gyrostat reference cases."
  alias OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels, as: Wheels
  @manifest "f7498ecf8f6e8dfebe32bf1a2908423f67926e5d56a738e962da9bf80ce7a95a"
  @files ~w(generate.py inputs.json reference.json)
  @ids ~w(stationary_zero stationary_disturbance external_unloading principal_acceleration unequal_inertia_rotating_body changing_axis_disturbance momentum_saturation gyroscopic_motor_saturation)

  def bundle_path, do: Application.app_dir(:orbital_dynamics, "priv/validation/reaction_wheels")

  def verify(directory \\ bundle_path()) do
    try do
      hashes = admit!(directory)
      inputs = decode(directory, "inputs.json")["cases"]
      reference = decode(directory, "reference.json")
      refs = Map.new(reference["cases"], &{&1["id"], &1})

      unless Enum.sort(Enum.map(inputs, & &1["id"])) == Enum.sort(@ids) and
               Enum.sort(Map.keys(refs)) == Enum.sort(@ids),
             do: raise(ArgumentError, "independent wheel case identities do not match")

      rows = for c <- inputs, step <- [1.0, 0.25], do: compare(c, refs[c["id"]], step)

      {:ok,
       %{
         "format" => "wheel_numerical_verification.v1",
         "status" => if(Enum.all?(rows, & &1["passed"]), do: "passed", else: "failed"),
         "manifest_sha256" => @manifest,
         "verified_sha256" => hashes,
         "reference_integrator" => reference["generator"],
         "reference_rk4_step_s" => reference["fine_rk4_step_s"],
         "reference_resolution_tolerance" => reference["convergence_tolerance"],
         "rows" => rows,
         "limits" => [
           "eight finite declared paths; not spacecraft engineering validation or a continuous feasibility certificate",
           "independent Python RK4 evolves quaternion and rotor state in body coordinates; production evolves inertial total momentum",
           "reference attitudes are prescribed inputs to production wheel evaluation; generated production attitude paths are outside this comparison",
           "capacity statuses are checked on the tested grids; cases are separated from thresholds, not grazing-limit certification",
           "nonzero external torque uses production midpoint quadrature; reported discrepancies include this integration error"
         ]
       }}
    rescue
      e in [ArgumentError, File.Error, MatchError, KeyError] ->
        {:error, {:wheel_reference_failed, Exception.message(e)}}
    end
  end

  defp admit!(dir) do
    manifest = File.read!(Path.join(dir, "SHA256SUMS"))

    unless sha(manifest) == @manifest,
      do: raise(ArgumentError, "wheel reference manifest identity mismatch")

    lines = String.split(manifest, "\n", trim: true)

    hashes =
      Map.new(lines, fn line ->
        [hash, file] = String.split(line, "  ")
        {file, hash}
      end)

    unless Enum.sort(Map.keys(hashes)) == Enum.sort(@files),
      do: raise(ArgumentError, "unexpected wheel reference files")

    for {file, hash} <- hashes do
      unless sha(File.read!(Path.join(dir, file))) == hash,
        do: raise(ArgumentError, "wheel reference content mismatch: #{file}")
    end

    hashes
  end

  defp sha(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  defp decode(dir, name), do: dir |> Path.join(name) |> File.read!() |> :json.decode()

  defp compare(c, ref, step) do
    config = %{
      "frame" => "body_principal_axes",
      "wheel_axes_body" => c["axes"],
      "principal_moments_kg_m2" => c["inertia"],
      "initial_momentum_nms" => c["initial_momentum"],
      "momentum_capacity_nms" => c["momentum_capacity"],
      "max_motor_torque_nm" => c["motor_capacity"],
      "disturbance_torque_body_nm" => c["disturbance"],
      "max_unload_torque_body_nm" => Enum.map(c["unload"], &abs/1),
      "unload_modes" =>
        if(c["id"] == "external_unloading",
          do: %{"dump" => %{"external_torque_body_nm" => c["unload"]}},
          else: %{}
        )
    }

    {:ok, session, _} = Wheels.prepare(nil, nil, config)
    samples = Map.new(ref["samples"], &{&1["t"], &1})
    unloading = c["id"] == "external_unloading"

    mode = %{
      "name" => if(unloading, do: "dump", else: "idle"),
      "parameters" => %{"momentum_unloading" => unloading}
    }

    initial = %{
      state: Wheels.initial(session),
      momentum: 0.0,
      motor: 0.0,
      total: 0.0,
      violations: false,
      unknown: false
    }

    measured =
      Enum.reduce(1..round(c["duration_s"] / step), initial, fn index, acc ->
        a = (index - 1) * step
        b = index * step
        mid = (a + b) / 2

        input = %{
          kinematics_start: samples[a]["pose"],
          kinematics_mid: samples[mid]["pose"],
          kinematics_end: samples[b]["pose"],
          mode: mode,
          phase: if(unloading, do: "activity", else: "hold"),
          activity_type: if(unloading, do: "momentum_unload", else: nil)
        }

        {:ok, next, result} = Wheels.step(acc.state, input, step, session)
        result = OrbitalDynamics.MissionAnalysis.Path.Result.validate!(result)

        %{
          state: next,
          momentum:
            max(
              acc.momentum,
              delta(Tuple.to_list(Wheels.vector(next)), samples[b]["momentum_nms"])
            ),
          motor:
            max(
              acc.motor,
              delta(result.metrics["motor_torque_mid_nm"], samples[mid]["motor_torque_nm"])
            ),
          total:
            max(
              acc.total,
              delta(
                result.metrics["total_inertial_angular_momentum_nms"],
                samples[b]["total_inertial_momentum_nms"]
              )
            ),
          violations: acc.violations or Enum.any?(result.checks, &(&1.status == :violated)),
          unknown: acc.unknown or Enum.any?(result.checks, &(&1.status == :unknown))
        }
      end)

    tolerance = if step == 1.0, do: 1.0e-4, else: 1.0e-5

    status =
      cond do
        measured.unknown -> "unknown"
        measured.violations -> "violated"
        true -> "supported"
      end

    conserved =
      if Enum.all?(c["disturbance"] ++ c["unload"], &(&1 == 0)) do
        first = hd(ref["samples"])["total_inertial_momentum_nms"]
        Enum.map(ref["samples"], &delta(first, &1["total_inertial_momentum_nms"])) |> Enum.max()
      else
        0.0
      end

    %{
      "case_id" => c["id"],
      "step_s" => step,
      "momentum_error_nms" => measured.momentum,
      "motor_error_nm" => measured.motor,
      "total_momentum_error_nms" => measured.total,
      "absolute_tolerance" => tolerance,
      "reference_resolution_delta" => ref["rk4_resolution_delta"],
      "reference_zero_torque_conservation_error_nms" => conserved,
      "expected_status" => ref["expected_status"],
      "actual_status" => status,
      "passed" =>
        status == ref["expected_status"] and measured.momentum <= tolerance and
          measured.motor <= tolerance and
          measured.total <= tolerance and conserved <= 1.0e-8 and
          ref["rk4_resolution_delta"] <= 1.0e-8
    }
  end

  defp delta(a, b), do: Enum.zip_with(a, b, &abs(&1 - &2)) |> Enum.max()
end
