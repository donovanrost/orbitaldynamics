defmodule OrbitalDynamics.EventSearch.ProductsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    StateVector,
    Target,
    Trajectory
  }

  alias OrbitalDynamics.EventSearch.Products
  alias OrbitalDynamics.AccessEventResultAdmission

  defp trajectory(frame \\ Frame.earth_inertial_j2000()) do
    %Trajectory{
      scenario_id: "source",
      assumptions: %{},
      states:
        for t <- [0, 60, 120] do
          StateVector.new!({7000, 7.5 * t, 0}, {0, 7.5, 0}, Epoch.new!(t, :tai), frame)
        end
    }
  end

  test "study access/visibility products retain accounted timing evidence and survive strict admission" do
    station = GroundStation.new!("station", 0, 0)
    target = Target.new!("target", 0, 0)

    for {kind, source, result} <- [
          {:ground_station_access, %{ground_station_id: "station"},
           Products.access(trajectory(), ground_station: station)},
          {:target_visibility, %{target_id: "target"},
           Products.visibility(trajectory(), target: target)}
        ] do
      assert {:ok, [event]} = result
      assert event.metadata.event_detector == :shared_event_search
      assert event.metadata.event_search["status"] == "complete_under_search_policy"

      assert event.metadata.event_search["source"]["provenance"]["evaluation"] ==
               "cubic_hermite_sample_interpolant"

      assert event.metadata.validation_level == :analysis

      assert {:ok, [%{events: [_]}], _} =
               AccessEventResultAdmission.admit_event_results([
                 %{scenario_id: "source", event_type: kind, source: source, events: [event]}
               ])
    end
  end

  test "invalid frame, body and angular inputs fail before producing event products" do
    station = GroundStation.new!("station", 0, 0)
    assert {:error, _} = Products.access(trajectory(Frame.earth_fixed()), ground_station: station)
    body = CentralBody.new!(:other, 1, equatorial_radius_km: 1)
    assert {:error, _} = Products.eclipse(trajectory(), central_body: body)
    assert {:error, _} = Products.crossing(trajectory(), crossing: :latitude, latitude_deg: 100)
    assert {:error, _} = Products.crossing(trajectory(), crossing: :longitude, longitude_deg: 181)
  end

  test "nonisolated coordinate zero remains incomplete instead of becoming an arbitrary crossing" do
    assert {:error, {:incomplete_event_search, report}} =
             Products.crossing(trajectory(), crossing: :latitude, latitude_deg: 0)

    assert report["status"] == "unknown"
  end
end
