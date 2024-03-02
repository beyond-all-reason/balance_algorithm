defmodule Teiserver.Battle.BalanceLibTest do
  use ExUnit.Case, async: false
  alias Teiserver.Battle.BalanceLib

  test "loser picks simple users" do
    result =
      BalanceLib.create_balance(
        [
          %{1 => 5},
          %{2 => 6},
          %{3 => 7},
          %{4 => 8}
        ],
        2,
        mode: :loser_picks
      )
      |> Map.drop([:logs, :time_taken])

    assert result == %{
             team_groups: %{
               1 => [
                 %{members: [4], count: 1, group_rating: 8, ratings: [8]},
                 %{members: [1], count: 1, group_rating: 5, ratings: [5]}
               ],
               2 => [
                 %{members: [3], count: 1, group_rating: 7, ratings: [7]},
                 %{members: [2], count: 1, group_rating: 6, ratings: [6]}
               ]
             },
             team_players: %{
               1 => [4, 1],
               2 => [3, 2]
             },
             ratings: %{
               1 => 13,
               2 => 13
             },
             captains: %{
               1 => 4,
               2 => 3
             },
             team_sizes: %{
               1 => 2,
               2 => 2
             },
             deviation: 0,
             means: %{1 => 6.5, 2 => 6.5},
             stdevs: %{1 => 1.5, 2 => 0.5}
           }
  end
end
