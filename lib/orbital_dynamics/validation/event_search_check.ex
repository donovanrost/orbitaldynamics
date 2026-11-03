defmodule OrbitalDynamics.Validation.EventSearchCheck do
  @moduledoc """
  Offline independent-reference checks for the migrated production event paths.
  Results are scoped numerical evidence, separate from the legacy external-truth
  registry. A pass never changes detector capabilities or mission acceptance.
  """
  alias OrbitalDynamics.Validation.EventSearch.{FiniteSunCheck, LeoCheck}

  def verify(group \\ :all) when group in [:all, :leo, :finite_sun] do
    try do
      results =
        for {name, module} <- [{"leo", LeoCheck}, {"finite_sun", FiniteSunCheck}],
            group == :all or Atom.to_string(group) == name do
          result =
            try do
              module.verify()
            rescue
              error -> {:error, Exception.message(error)}
            catch
              kind, reason -> {:error, {kind, reason}}
            end

          case result do
            {:ok, report} -> {name, report}
            {:error, reason} -> {name, %{"status" => "error", "reason" => inspect(reason)}}
          end
        end

      groups = Map.new(results)

      {:ok,
       %{
         "format" => "event_reference_check.v1",
         "status" =>
           if(Enum.all?(results, fn {_, r} -> r["status"] == "pass" end),
             do: "pass",
             else: "fail"
           ),
         "validation_scope" =>
           "matched-model independent numerical cases; no general or operational acceptance",
         "groups" => groups
       }}
    rescue
      error -> {:error, {:event_reference_check_failed, Exception.message(error)}}
    end
  end

  def markdown(report) do
    leo = get_in(report, ["groups", "leo"])
    finite = get_in(report, ["groups", "finite_sun"])

    leo_rows =
      if is_map(leo) and leo["status"] in ["pass", "fail"] do
        interpolation =
          for row <- leo["interpolation_and_root_precision"] do
            "| Orekit anchors / root #{row["root_tolerance_s"]} s | #{row["access"]["max_absolute_error_s"]} | #{row["eclipse"]["max_absolute_error_s"]} | #{row["status"]} |"
          end

        propagated =
          for row <- leo["propagation_and_output_sensitivity"] do
            "| Project integration #{row["integration_step_s"]} s / output #{row["output_step_s"]} s (Orekit #{row["reference_integrator_step_s"]} s) | #{row["access"]["max_absolute_error_s"]} | #{row["eclipse"]["max_absolute_error_s"]} | #{row["status"]} |"
          end

        [
          "\n## Frozen six-hour Orekit case\n",
          "Maximum absolute boundary residuals against independent Orekit events. Tolerance: 0.001 s for each family. State residuals and actual runtime parameters are checked separately in report.json.\n",
          "| State source | Access error s | Cylindrical eclipse error s | Status |",
          "| --- | --- | --- | --- |"
        ] ++ interpolation ++ propagated
      else
        []
      end

    finite_rows =
      if is_map(finite) and finite["status"] in ["pass", "fail"] do
        [
          "\n## Finite-Sun geometry and power\n",
          "Frozen Orekit angular geometry and Brent contacts; independent numerical disk-area integration. Power uses the same declared uniform-disk/center-ray approximation as production.\n",
          "| Case | Samples | Maximum fraction error | Maximum bus power error W | Status |",
          "| --- | --- | --- | --- | --- |"
        ] ++
          Enum.map(finite["cases"], fn c ->
            "| #{c["id"]} | #{c["sample_count"]} | #{c["max_fraction_error"]} | #{c["max_power_error_w"]} | #{c["status"]} |"
          end)
      else
        []
      end

    Enum.join(
      ["# Independent event-reference checks\n", "Status: #{report["status"]}.\n"] ++
        leo_rows ++
        finite_rows ++
        [
          "\nFull per-event signed residuals, root brackets, missing/extra event diagnostics, search policies, sample differences and frozen content identities are in report.json.",
          "\nRoot precision, interpolated-state error and propagation sensitivity are separate evidence. A finer integration or output grid is not assumed to be truth. These finite cases do not establish global event completeness, physical spacecraft accuracy or operations acceptance."
        ],
      "\n"
    ) <> "\n"
  end
end
