defmodule OrbitalDynamics.DistributedStudyRunnerTest do
  use ExUnit.Case, async: false

  alias OrbitalDynamics.{CentralBody, Epoch, Frame, Scenario, Spacecraft, StateVector, Study}

  test "can run a study through a remote task supervisor when distribution is available" do
    case start_peer() do
      {:ok, peer, peer_node, cleanup} ->
        try do
          earth = CentralBody.earth()
          study = Study.new!(:remote_study, [scenario(:a, earth)], outputs: [:trajectories])

          assert {:ok, result_set} =
                   OrbitalDynamics.run_study(study,
                     task_supervisor: {OrbitalDynamics.ScenarioSupervisor, peer_node},
                     max_concurrency: 1
                   )

          assert [%{scenario_id: :a, node: ^peer_node}] = result_set.trajectory_results
          assert result_set.metadata.run["metadata"]["execution_mode"] == "remote_task_supervisor"

          assert result_set.metadata.run["metadata"]["task_supervisor_node"] ==
                   Atom.to_string(peer_node)
        after
          stop_peer(peer)
          cleanup.()
        end

      {:skip, _reason} ->
        :ok
    end
  end

  test "can distribute a study across local and remote task supervisors" do
    case start_peer() do
      {:ok, peer, peer_node, cleanup} ->
        try do
          earth = CentralBody.earth()

          scenarios =
            for id <- [:a, :b, :c, :d] do
              scenario(id, earth)
            end

          study = Study.new!(:distributed_study, scenarios, outputs: [:trajectories])

          assert {:ok, result_set} =
                   OrbitalDynamics.run_study(study,
                     task_supervisors: [
                       OrbitalDynamics.ScenarioSupervisor,
                       {OrbitalDynamics.ScenarioSupervisor, peer_node}
                     ],
                     max_concurrency: 4
                   )

          assert Enum.map(result_set.trajectory_results, & &1.scenario_id) == [:a, :b, :c, :d]

          assert result_set.metadata.run["metadata"]["execution_mode"] ==
                   "distributed_task_supervisors"

          assert result_set.metadata.run["metadata"]["task_supervisor_nodes"] == [
                   Atom.to_string(node()),
                   Atom.to_string(peer_node)
                 ]

          node_counts =
            result_set.trajectory_results
            |> Enum.group_by(& &1.node)
            |> Map.new(fn {node, rows} -> {node, length(rows)} end)

          assert node_counts[node()] == 2
          assert node_counts[peer_node] == 2
        after
          stop_peer(peer)
          cleanup.()
        end

      {:skip, _reason} ->
        :ok
    end
  end

  defp start_peer do
    with {:ok, stop_node?} <- ensure_distributed_node(),
         {:ok, peer, peer_node} <- start_peer_node() do
      case prepare_peer(peer) do
        :ok ->
          {:ok, peer, peer_node, fn -> if stop_node?, do: Node.stop() end}

        {:error, reason} ->
          stop_peer(peer)
          if stop_node?, do: Node.stop()
          {:skip, reason}
      end
    else
      {:error, reason} -> {:skip, reason}
      {:skip, reason} -> {:skip, reason}
    end
  end

  defp ensure_distributed_node do
    if Node.alive?() do
      {:ok, false}
    else
      node_name = :"orbital_dynamics_test_#{System.unique_integer([:positive])}"

      case Node.start(node_name, :shortnames) do
        {:ok, _pid} -> {:ok, true}
        {:error, reason} -> {:skip, reason}
      end
    end
  catch
    :exit, reason -> {:skip, reason}
  end

  defp start_peer_node do
    peer_name = :"orbital_dynamics_peer_#{System.unique_integer([:positive])}"

    case :peer.start_link(%{name: peer_name}) do
      {:ok, peer, peer_node} -> {:ok, peer, peer_node}
      {:error, reason} -> {:error, reason}
    end
  catch
    :exit, reason -> {:error, reason}
  end

  defp prepare_peer(peer) do
    :ok = :peer.call(peer, :code, :add_paths, [:code.get_path()])

    case :peer.call(peer, Application, :ensure_all_started, [:orbital_dynamics]) do
      {:ok, _apps} -> :ok
      {:error, reason} -> {:error, reason}
    end
  rescue
    error in ErlangError -> {:error, error.original}
  catch
    :exit, reason -> {:error, reason}
  end

  defp stop_peer(peer) do
    :peer.stop(peer)
  catch
    :exit, _reason -> :ok
  end

  defp scenario(id, earth) do
    Scenario.new!(id, Spacecraft.new!(:"sat_#{id}", 250.0), state({7_000.0, 0.0, 0.0}, earth),
      duration_s: 120.0,
      output_step_s: 60.0,
      central_body: earth
    )
  end

  defp state(position_km, earth) do
    velocity_km_s = :math.sqrt(earth.mu_km3_s2 / 7_000.0)

    StateVector.new!(
      position_km,
      {0.0, velocity_km_s, 0.0},
      Epoch.new!(0.0, :tdb),
      Frame.earth_inertial_j2000()
    )
  end
end
