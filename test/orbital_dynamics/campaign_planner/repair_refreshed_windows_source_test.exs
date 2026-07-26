defmodule OrbitalDynamics.CampaignPlanner.RepairRefreshedWindowsSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves the exact normalized refreshed-window collections" do
    windows = %{
      access_windows: [
        %{
          id: "window:leo_1:ground_station_access:equator_prime:1",
          type: "ground_station_access"
        }
      ],
      target_visibility_windows: [],
      eclipse_intervals: []
    }

    assert RepairSourceReports.refreshed_windows(%{refreshed_windows: windows}) == %{
             "access_windows" => [
               %{
                 "id" => "window:leo_1:ground_station_access:equator_prime:1",
                 "type" => "ground_station_access"
               }
             ],
             "target_visibility_windows" => [],
             "eclipse_intervals" => []
           }
  end

  test "distinguishes an empty typed opportunity set from absent windows" do
    empty = %{
      "access_windows" => [],
      "target_visibility_windows" => [],
      "eclipse_intervals" => []
    }

    assert RepairSourceReports.refreshed_windows(%{"refreshed_windows" => empty}) == empty
    assert RepairSourceReports.refreshed_windows(%{}) == nil
    assert RepairSourceReports.refreshed_windows(nil) == nil
  end
end
