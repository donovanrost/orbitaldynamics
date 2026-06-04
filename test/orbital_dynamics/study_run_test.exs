defmodule OrbitalDynamics.StudyRunTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    Scenario,
    Spacecraft,
    StateVector,
    Study,
    StudyRun
  }

  test "creates an execution record from a study" do
    study = Study.new!(:leo_access, [scenario(:a)], propagator_opts: [max_step_s: 10.0])
    started_at = DateTime.from_unix!(1_700_000_000)
    completed_at = DateTime.from_unix!(1_700_000_001)
    expected_node = node()

    assert %StudyRun{
             id: :run_1,
             study_id: :leo_access,
             status: :completed,
             backend: OrbitalDynamics.Propagators.TwoBody,
             node: ^expected_node,
             options: [max_step_s: 10.0],
             seed_manifest: %{},
             started_at: ^started_at,
             completed_at: ^completed_at,
             duration_ms: 1_000,
             assumptions: %{force_model: :point_mass_two_body},
             results: [:ok],
             errors: [],
             metadata: %{operator: "test"}
           } =
             StudyRun.new!(:run_1, study,
               status: :completed,
               started_at: started_at,
               completed_at: completed_at,
               duration_ms: 1_000,
               assumptions: %{force_model: :point_mass_two_body},
               results: [:ok],
               metadata: %{operator: "test"}
             )
  end

  test "converts execution records to JSON-friendly maps" do
    study = Study.new!(:leo_access, [scenario(:a)], propagator_opts: [max_step_s: 10.0])
    started_at = DateTime.from_unix!(1_700_000_000)
    completed_at = DateTime.from_unix!(1_700_000_001)

    run =
      StudyRun.new!(:run_1, study,
        status: :completed,
        started_at: started_at,
        completed_at: completed_at,
        duration_ms: 1_000,
        assumptions: %{force_model: :point_mass_two_body},
        results: [:ok],
        metadata: %{execution_mode: :local_tasks}
      )

    assert StudyRun.to_map(run) == %{
             "id" => "run_1",
             "study_id" => "leo_access",
             "status" => "completed",
             "backend" => "Elixir.OrbitalDynamics.Propagators.TwoBody",
             "node" => Atom.to_string(node()),
             "options" => %{"max_step_s" => 10.0},
             "seed_manifest" => %{},
             "started_at" => "2023-11-14T22:13:20Z",
             "completed_at" => "2023-11-14T22:13:21Z",
             "duration_ms" => 1_000,
             "assumptions" => %{"force_model" => "point_mass_two_body"},
             "results" => ["ok"],
             "errors" => [],
             "metadata" => %{"execution_mode" => "local_tasks"}
           }
  end

  test "rejects invalid execution record fields" do
    study = Study.new!(:leo_access, [scenario(:a)])

    assert_raise ArgumentError, "study run id is required", fn ->
      StudyRun.new!("", study)
    end

    assert_raise ArgumentError,
                 "status must be one of :created, :running, :completed, or :failed",
                 fn ->
                   StudyRun.new!(:run_1, study, status: :unknown)
                 end

    assert_raise ArgumentError, "duration_ms must be nil or a non-negative integer", fn ->
      StudyRun.new!(:run_1, study, duration_ms: -1)
    end
  end

  defp scenario(id) do
    central_body = CentralBody.earth()
    radius_km = 7_000.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)

    state =
      StateVector.new!(
        {radius_km, 0.0, 0.0},
        {0.0, velocity_km_s, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    spacecraft = Spacecraft.new!(:"sat_#{id}", 250.0)

    Scenario.new!(id, spacecraft, state,
      duration_s: 600.0,
      output_step_s: 60.0,
      central_body: central_body
    )
  end
end
