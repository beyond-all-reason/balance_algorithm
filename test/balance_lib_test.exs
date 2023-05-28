defmodule Teiserver.Battle.BalanceLibTest do
  use ExUnit.Case, async: true
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

  test "loser picks ffa" do
    result =
      BalanceLib.create_balance(
        [
          %{1 => 5},
          %{2 => 6},
          %{3 => 7},
          %{4 => 8}
        ],
        4,
        mode: :loser_picks
      )
      |> Map.drop([:logs, :time_taken])

    assert result == %{
             team_groups: %{
               1 => [%{members: [4], count: 1, group_rating: 8, ratings: [8]}],
               2 => [%{count: 1, group_rating: 7, members: [3], ratings: [7]}],
               3 => [%{count: 1, group_rating: 6, members: [2], ratings: [6]}],
               4 => [%{count: 1, group_rating: 5, members: [1], ratings: [5]}]
             },
             team_players: %{
               1 => [4],
               2 => [3],
               3 => [2],
               4 => [1]
             },
             ratings: %{
               1 => 8,
               2 => 7,
               3 => 6,
               4 => 5
             },
             captains: %{
               1 => 4,
               2 => 3,
               3 => 2,
               4 => 1
             },
             team_sizes: %{
               1 => 1,
               2 => 1,
               3 => 1,
               4 => 1
             },
             deviation: 13,
             means: %{1 => 8.0, 2 => 7.0, 3 => 6.0, 4 => 5.0},
             stdevs: %{1 => 0.0, 2 => 0.0, 3 => 0.0, 4 => 0.0}
           }
  end

  test "loser picks team ffa" do
    result =
      BalanceLib.create_balance(
        [
          %{1 => 5},
          %{2 => 6},
          %{3 => 7},
          %{4 => 8},
          %{5 => 9},
          %{6 => 9}
        ],
        3,
        mode: :loser_picks
      )
      |> Map.drop([:logs, :time_taken])

    assert result == %{
             team_groups: %{
               1 => [
                 %{count: 1, group_rating: 9, members: [5], ratings: [9]},
                 %{count: 1, group_rating: 6, members: [2], ratings: [6]}
               ],
               2 => [
                 %{count: 1, group_rating: 9, members: [6], ratings: [9]},
                 %{count: 1, group_rating: 5, members: [1], ratings: [5]}
               ],
               3 => [
                 %{count: 1, group_rating: 8, members: [4], ratings: [8]},
                 %{count: 1, group_rating: 7, members: [3], ratings: [7]}
               ]
             },
             team_players: %{
               1 => [5, 2],
               2 => [6, 1],
               3 => [4, 3]
             },
             ratings: %{
               1 => 15,
               2 => 14,
               3 => 15
             },
             captains: %{
               1 => 5,
               2 => 6,
               3 => 4
             },
             team_sizes: %{
               1 => 2,
               2 => 2,
               3 => 2
             },
             deviation: 0,
             means: %{1 => 7.5, 2 => 7.0, 3 => 7.5},
             stdevs: %{1 => 1.5, 2 => 2.0, 3 => 0.5}
           }
  end

  test "loser picks simple group" do
    result =
      BalanceLib.create_balance(
        [
          %{4 => 5, 1 => 8},
          %{2 => 6},
          %{3 => 7}
        ],
        2,
        mode: :loser_picks,
        rating_lower_boundary: 100,
        rating_upper_boundary: 100,
        mean_diff_max: 100,
        stddev_diff_max: 100
      )
      |> Map.drop([:logs, :time_taken])

    assert result == %{
             team_groups: %{
               1 => [
                 %{count: 2, group_rating: 13, members: [1, 4], ratings: [8, 5]}
               ],
               2 => [
                 %{count: 2, group_rating: 13, members: [2, 3], ratings: [6, 7]}
               ]
             },
             team_players: %{
               1 => [1, 4],
               2 => [2, 3]
             },
             ratings: %{
               1 => 13,
               2 => 13
             },
             captains: %{
               1 => 1,
               2 => 2
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

  test "loser picks bigger game group" do
    result =
      BalanceLib.create_balance(
        [
          # Two high tier players partied together
          %{101 => 41, 102 => 35},

          # A bunch of mid-low tier players together
          %{103 => 20, 104 => 17, 105 => 13.5},

          # A smaller bunch of even lower tier players
          %{106 => 15, 107 => 7.5},

          # Other players, a range of ratings
          %{108 => 31},
          %{109 => 26},
          %{110 => 25},
          %{111 => 21},
          %{112 => 19},
          %{113 => 16},
          %{114 => 16},
          %{115 => 14},
          %{116 => 8}
        ],
        2,
        mode: :loser_picks,
        rating_lower_boundary: 5,
        rating_upper_boundary: 5,
        mean_diff_max: 5,
        stddev_diff_max: 5
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 112, 2 => 103},
             deviation: 2,
             ratings: %{1 => 161, 2 => 164},
             team_groups: %{
               1 => [
                 %{count: 3, group_rating: 51, members: [112, 113, 114], ratings: [19, 16, 16]},
                 %{count: 2, group_rating: 22, members: [115, 116], ratings: [14, 8]},
                 %{count: 1, group_rating: 41, members: [101], ratings: [41]},
                 %{count: 1, group_rating: 26, members: [109], ratings: [26]},
                 %{count: 1, group_rating: 21, members: [111], ratings: [21]}
               ],
               2 => [
                 %{
                   count: 3,
                   group_rating: 50.5,
                   members: [103, 104, 105],
                   ratings: [20, 17, 13.5]
                 },
                 %{count: 2, group_rating: 22.5, members: [106, 107], ratings: [15, 7.5]},
                 %{count: 1, group_rating: 35, members: [102], ratings: [35]},
                 %{count: 1, group_rating: 31, members: [108], ratings: [31]},
                 %{count: 1, group_rating: 25, members: [110], ratings: [25]}
               ]
             },
             team_players: %{
               1 => [112, 113, 114, 115, 116, 101, 109, 111],
               2 => [103, 104, 105, 106, 107, 102, 108, 110]
             },
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 20.125, 2 => 20.5},
             stdevs: %{1 => 9.29297449689818, 2 => 8.671072598012312}
           }
  end

  test "smurf party" do
    result =
      BalanceLib.create_balance(
        [
          # Our smurf party
          %{101 => 51, 102 => 10, 103 => 10},

          # Other players, a range of ratings
          %{104 => 35},
          %{105 => 34},
          %{106 => 29},
          %{107 => 28},
          %{108 => 27},
          %{109 => 26},
          %{110 => 25},
          %{111 => 21},
          %{112 => 19},
          %{113 => 16},
          %{114 => 15},
          %{115 => 14},
          %{116 => 8}
        ],
        2,
        mode: :loser_picks
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 101, 2 => 104},
             deviation: 0,
             ratings: %{1 => 184, 2 => 184},
             team_groups: %{
               1 => [
                 %{count: 1, group_rating: 51, members: [101], ratings: [51]},
                 %{count: 1, group_rating: 29, members: [106], ratings: [29]},
                 %{count: 1, group_rating: 27, members: [108], ratings: [27]},
                 %{count: 1, group_rating: 25, members: [110], ratings: [25]},
                 %{count: 1, group_rating: 19, members: [112], ratings: [19]},
                 %{count: 1, group_rating: 15, members: [114], ratings: [15]},
                 %{count: 1, group_rating: 10, members: [102], ratings: [10]},
                 %{count: 1, group_rating: 8, members: [116], ratings: [8]}
               ],
               2 => [
                 %{count: 1, group_rating: 35, members: [104], ratings: '#'},
                 %{count: 1, group_rating: 34, members: [105], ratings: [34]},
                 %{count: 1, group_rating: 28, members: [107], ratings: [28]},
                 %{count: 1, group_rating: 26, members: [109], ratings: [26]},
                 %{count: 1, group_rating: 21, members: [111], ratings: [21]},
                 %{count: 1, group_rating: 16, members: [113], ratings: [16]},
                 %{count: 1, group_rating: 14, members: [115], ratings: [14]},
                 %{count: 1, group_rating: 10, members: [103], ratings: '\n'}
               ]
             },
             team_players: %{1 => 'ejlnprft', 2 => 'hikmoqsg'},
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 23.0, 2 => 23.0},
             stdevs: %{1 => 12.816005617976296, 2 => 8.674675786448736}
           }
  end

  # @tag runnable: true
  test "loser_picks: two parties" do
    result =
      BalanceLib.create_balance(
        [
          # Our high tier party
          %{101 => 52, 102 => 50, 103 => 49},

          # Our other high tier party
          %{104 => 51, 105 => 50, 106 => 50},

          # Other players, a range of ratings
          %{107 => 28},
          %{108 => 27},
          %{109 => 26},
          %{110 => 25},
          %{111 => 21},
          %{112 => 19},
          %{113 => 16},
          %{114 => 15},
          %{115 => 14},
          %{116 => 8}
        ],
        2,
        mode: :loser_picks
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 104, 2 => 101},
             deviation: 2,
             ratings: %{1 => 248, 2 => 253},
             team_groups: %{
               1 => [
                 %{count: 3, group_rating: 151, members: [104, 105, 106], ratings: [51, 50, 50]},
                 %{count: 1, group_rating: 28, members: [107], ratings: [28]},
                 %{count: 1, group_rating: 25, members: [110], ratings: [25]},
                 %{count: 1, group_rating: 21, members: [111], ratings: [21]},
                 %{count: 1, group_rating: 15, members: [114], ratings: [15]},
                 %{count: 1, group_rating: 8, members: [116], ratings: [8]}
               ],
               2 => [
                 %{count: 3, group_rating: 151, members: [101, 102, 103], ratings: [52, 50, 49]},
                 %{count: 1, group_rating: 27, members: [108], ratings: [27]},
                 %{count: 1, group_rating: 26, members: [109], ratings: [26]},
                 %{count: 1, group_rating: 19, members: [112], ratings: [19]},
                 %{count: 1, group_rating: 16, members: [113], ratings: [16]},
                 %{count: 1, group_rating: 14, members: [115], ratings: [14]}
               ]
             },
             team_players: %{
               1 => [104, 105, 106, 107, 110, 111, 114, 116],
               2 => [101, 102, 103, 108, 109, 112, 113, 115]
             },
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 31.0, 2 => 31.625},
             stdevs: %{1 => 16.015617378046965, 2 => 15.090870584562046}
           }

    result2 =
      BalanceLib.create_balance(
        [
          # Our high tier party
          %{101 => 52, 102 => 50, 103 => 49},

          # Our other high tier party, only 2 people this time
          %{104 => 51, 105 => 50},

          # Other players, a range of ratings
          %{106 => 50},
          %{107 => 28},
          %{108 => 27},
          %{109 => 26},
          %{110 => 25},
          %{111 => 21},
          %{112 => 19},
          %{113 => 16},
          %{114 => 15},
          %{115 => 14},
          %{116 => 8}
        ],
        2,
        mode: :loser_picks
      )

    # This is very similar to the previous one but a few things about the exact
    # pick order is different
    assert Map.drop(result2, [:logs, :time_taken]) == %{
             captains: %{1 => 101, 2 => 106},
             deviation: 2,
             ratings: %{1 => 248, 2 => 253},
             team_groups: %{
               1 => [
                 %{count: 3, group_rating: 151, members: [101, 102, 103], ratings: [52, 50, 49]},
                 %{count: 1, group_rating: 28, members: [107], ratings: [28]},
                 %{count: 1, group_rating: 25, members: [110], ratings: [25]},
                 %{count: 1, group_rating: 21, members: [111], ratings: [21]},
                 %{count: 1, group_rating: 15, members: [114], ratings: [15]},
                 %{count: 1, group_rating: 8, members: [116], ratings: [8]}
               ],
               2 => [
                 %{count: 3, group_rating: 151, members: [106, 104, 105], ratings: [50, 51, 50]},
                 %{count: 1, group_rating: 27, members: [108], ratings: [27]},
                 %{count: 1, group_rating: 26, members: [109], ratings: [26]},
                 %{count: 1, group_rating: 19, members: [112], ratings: [19]},
                 %{count: 1, group_rating: 16, members: [113], ratings: [16]},
                 %{count: 1, group_rating: 14, members: [115], ratings: [14]}
               ]
             },
             team_players: %{
               1 => [101, 102, 103, 107, 110, 111, 114, 116],
               2 => [106, 104, 105, 108, 109, 112, 113, 115]
             },
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 31.0, 2 => 31.625},
             stdevs: %{1 => 16.0312195418814, 2 => 15.074295174236173}
           }
  end

  test "cheeky_switcher: team ffa" do
    result =
      BalanceLib.create_balance(
        [
          %{1 => 5},
          %{2 => 6},
          %{3 => 7},
          %{4 => 8},
          %{5 => 9},
          %{6 => 9}
        ],
        3,
        algorithm: :cheeky_switcher
      )
      |> Map.drop([:logs, :time_taken])

    assert result == %{
             team_groups: %{
               1 => [
                 %{count: 1, group_rating: 9, members: [5], ratings: [9]},
                 %{count: 1, group_rating: 6, members: [2], ratings: [6]}
               ],
               2 => [
                 %{count: 1, group_rating: 9, members: [6], ratings: [9]},
                 %{count: 1, group_rating: 5, members: [1], ratings: [5]}
               ],
               3 => [
                 %{count: 1, group_rating: 8, members: [4], ratings: [8]},
                 %{count: 1, group_rating: 7, members: [3], ratings: [7]}
               ]
             },
             team_players: %{
               1 => [5, 2],
               2 => [6, 1],
               3 => [4, 3]
             },
             ratings: %{
               1 => 15,
               2 => 14,
               3 => 15
             },
             captains: %{
               1 => 5,
               2 => 6,
               3 => 4
             },
             team_sizes: %{
               1 => 2,
               2 => 2,
               3 => 2
             },
             deviation: 0,
             means: %{1 => 7.5, 2 => 7.0, 3 => 7.5},
             stdevs: %{1 => 1.5, 2 => 2.0, 3 => 0.5}
           }
  end

  # @tag runnable: true
  test "cheeky_switcher: MasterBel2 case" do
    result =
      BalanceLib.create_balance(
        [
          %{:hitman => 9.39, :kayme => 15.14},
          %{:eural => 28.84, :morgan => 15.06},
          %{:zerpiderp => 43.69},
          %{:gabb => 29.56},
          %{:flaka => 28.27},
          %{:gegx001 => 25.34},
          %{:lordvenom1 => 23.45},
          %{:notlobsters => 21.65},
          %{:trimbil => 21.6},
          %{:redspatula => 18.46},
          %{:claaay => 17.7},
          %{:korbal22 => 16.29},
          %{:p4r0 => 16.01},
          %{:amadeuz => 10.27}
        ],
        2,
        algorithm: :cheeky_switcher
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 105, 2 => 106},
             deviation: 2,
             ratings: %{1 => 248, 2 => 253},
             team_groups: %{
               1 => [
                 %{count: 2, group_rating: 24.53, members: [101, 102], ratings: [9.39, 15.14]},
                 %{count: 1, group_rating: 43.69, members: [105], ratings: [43.69]},
                 %{count: 1, group_rating: 29.56, members: [106], ratings: [29.56]},
                 %{count: 1, group_rating: 28.27, members: [107], ratings: [28.27]},
                 %{count: 1, group_rating: 25.34, members: [108], ratings: [25.34]},
                 %{count: 1, group_rating: 23.45, members: [109], ratings: [23.45]},
                 %{count: 1, group_rating: 10.27, members: [116], ratings: [10.27]}
               ],
               2 => [
                 %{count: 2, group_rating: 43.9, members: [103, 104], ratings: [28.84, 15.06]},
                 %{count: 1, group_rating: 21.65, members: [110], ratings: [21.65]},
                 %{count: 1, group_rating: 21.6, members: [111], ratings: [21.6]},
                 %{count: 1, group_rating: 18.46, members: [112], ratings: [18.46]},
                 %{count: 1, group_rating: 17.7, members: [113], ratings: [17.7]},
                 %{count: 1, group_rating: 16.29, members: [114], ratings: [16.29]},
                 %{count: 1, group_rating: 16.01, members: [115], ratings: [16.01]}
               ]
             },
             team_players: %{
               1 => [104, 105, 106, 107, 110, 111, 114, 116],
               2 => [101, 102, 103, 108, 109, 112, 113, 115]
             },
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 31.0, 2 => 31.625},
             stdevs: %{1 => 16.015617378046965, 2 => 15.090870584562046}
           }
  end

  # @tag runnable: true
  test "loser_picks: MasterBel2 case" do
    result =
      BalanceLib.create_balance(
        [
          %{:hitman => 9.39, :kayme => 15.14},
          %{:eural => 28.84, :morgan => 15.06},
          %{:zerpiderp => 43.69},
          %{:gabb => 29.56},
          %{:flaka => 28.27},
          %{:gegx001 => 25.34},
          %{:lordvenom1 => 23.45},
          %{:notlobsters => 21.65},
          %{:trimbil => 21.6},
          %{:redspatula => 18.46},
          %{:claaay => 17.7},
          %{:korbal22 => 16.29},
          %{:p4r0 => 16.01},
          %{:amadeuz => 10.27}
        ],
        2,
        algorithm: :loser_picks
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 105, 2 => 106},
             deviation: 2,
             ratings: %{1 => 248, 2 => 253},
             team_groups: %{
               1 => [
                 %{count: 2, group_rating: 24.53, members: [101, 102], ratings: [9.39, 15.14]},
                 %{count: 1, group_rating: 43.69, members: [105], ratings: [43.69]},
                 %{count: 1, group_rating: 29.56, members: [106], ratings: [29.56]},
                 %{count: 1, group_rating: 28.27, members: [107], ratings: [28.27]},
                 %{count: 1, group_rating: 25.34, members: [108], ratings: [25.34]},
                 %{count: 1, group_rating: 23.45, members: [109], ratings: [23.45]},
                 %{count: 1, group_rating: 10.27, members: [116], ratings: [10.27]}
               ],
               2 => [
                 %{count: 2, group_rating: 43.9, members: [103, 104], ratings: [28.84, 15.06]},
                 %{count: 1, group_rating: 21.65, members: [110], ratings: [21.65]},
                 %{count: 1, group_rating: 21.6, members: [111], ratings: [21.6]},
                 %{count: 1, group_rating: 18.46, members: [112], ratings: [18.46]},
                 %{count: 1, group_rating: 17.7, members: [113], ratings: [17.7]},
                 %{count: 1, group_rating: 16.29, members: [114], ratings: [16.29]},
                 %{count: 1, group_rating: 16.01, members: [115], ratings: [16.01]}
               ]
             },
             team_players: %{
               1 => [104, 105, 106, 107, 110, 111, 114, 116],
               2 => [101, 102, 103, 108, 109, 112, 113, 115]
             },
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 31.0, 2 => 31.625},
             stdevs: %{1 => 16.015617378046965, 2 => 15.090870584562046}
           }
  end

  # @tag runnable: true
  test "brute: MasterBel2 case" do
    result =
      BalanceLib.create_balance(
        [
          %{:hitman => 9.39, :kayme => 15.14},
          %{:eural => 28.84, :morgan => 15.06},
          %{:zerpiderp => 43.69},
          %{:gabb => 29.56},
          %{:flaka => 28.27},
          %{:gegx001 => 25.34},
          %{:lordvenom1 => 23.45},
          %{:notlobsters => 21.65},
          %{:trimbil => 21.6},
          %{:redspatula => 18.46},
          %{:claaay => 17.7},
          %{:korbal22 => 16.29},
          %{:p4r0 => 16.01},
          %{:amadeuz => 10.27}
        ],
        2,
        algorithm: :brute_force
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 105, 2 => 106},
             deviation: 2,
             ratings: %{1 => 248, 2 => 253},
             team_groups: %{
               1 => [
                 %{count: 2, group_rating: 24.53, members: [101, 102], ratings: [9.39, 15.14]},
                 %{count: 1, group_rating: 43.69, members: [105], ratings: [43.69]},
                 %{count: 1, group_rating: 29.56, members: [106], ratings: [29.56]},
                 %{count: 1, group_rating: 28.27, members: [107], ratings: [28.27]},
                 %{count: 1, group_rating: 25.34, members: [108], ratings: [25.34]},
                 %{count: 1, group_rating: 23.45, members: [109], ratings: [23.45]},
                 %{count: 1, group_rating: 10.27, members: [116], ratings: [10.27]}
               ],
               2 => [
                 %{count: 2, group_rating: 43.9, members: [103, 104], ratings: [28.84, 15.06]},
                 %{count: 1, group_rating: 21.65, members: [110], ratings: [21.65]},
                 %{count: 1, group_rating: 21.6, members: [111], ratings: [21.6]},
                 %{count: 1, group_rating: 18.46, members: [112], ratings: [18.46]},
                 %{count: 1, group_rating: 17.7, members: [113], ratings: [17.7]},
                 %{count: 1, group_rating: 16.29, members: [114], ratings: [16.29]},
                 %{count: 1, group_rating: 16.01, members: [115], ratings: [16.01]}
               ]
             },
             team_players: %{
               1 => [104, 105, 106, 107, 110, 111, 114, 116],
               2 => [101, 102, 103, 108, 109, 112, 113, 115]
             },
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 31.0, 2 => 31.625},
             stdevs: %{1 => 16.015617378046965, 2 => 15.090870584562046}
           }
  end

  test "cheeky_switcher: bigger game group" do
    result =
      BalanceLib.create_balance(
        [
          # Two high tier players partied together
          %{101 => 41, 102 => 35},

          # A bunch of mid-low tier players together
          %{103 => 20, 104 => 17, 105 => 13.5},

          # A smaller bunch of even lower tier players
          %{106 => 15, 107 => 7.5},

          # Other players, a range of ratings
          %{108 => 31},
          %{109 => 26},
          %{110 => 25},
          %{111 => 21},
          %{112 => 19},
          %{113 => 16},
          %{114 => 16},
          %{115 => 14},
          %{116 => 8}
        ],
        2,
        algorithm: :cheeky_switcher,
        rating_lower_boundary: 5,
        rating_upper_boundary: 5,
        mean_diff_max: 5,
        stddev_diff_max: 5
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 112, 2 => 103},
             deviation: 2,
             ratings: %{1 => 161, 2 => 164},
             team_groups: %{
               1 => [
                 %{count: 3, group_rating: 51, members: [112, 113, 114], ratings: [19, 16, 16]},
                 %{count: 2, group_rating: 22, members: [115, 116], ratings: [14, 8]},
                 %{count: 1, group_rating: 41, members: [101], ratings: [41]},
                 %{count: 1, group_rating: 26, members: [109], ratings: [26]},
                 %{count: 1, group_rating: 21, members: [111], ratings: [21]}
               ],
               2 => [
                 %{
                   count: 3,
                   group_rating: 50.5,
                   members: [103, 104, 105],
                   ratings: [20, 17, 13.5]
                 },
                 %{count: 2, group_rating: 22.5, members: [106, 107], ratings: [15, 7.5]},
                 %{count: 1, group_rating: 35, members: [102], ratings: [35]},
                 %{count: 1, group_rating: 31, members: [108], ratings: [31]},
                 %{count: 1, group_rating: 25, members: [110], ratings: [25]}
               ]
             },
             team_players: %{
               1 => [112, 113, 114, 115, 116, 101, 109, 111],
               2 => [103, 104, 105, 106, 107, 102, 108, 110]
             },
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 20.125, 2 => 20.5},
             stdevs: %{1 => 9.29297449689818, 2 => 8.671072598012312}
           }
  end

  # @tag runnable: true
  test "cheeky_switcher: smurf party" do
    result =
      BalanceLib.create_balance(
        [
          # Our smurf party
          %{101 => 51, 102 => 10, 103 => 10},

          # Other players, a range of ratings
          %{104 => 35},
          %{105 => 34},
          %{106 => 29},
          %{107 => 28},
          %{108 => 27},
          %{109 => 26},
          %{110 => 25},
          %{111 => 21},
          %{112 => 19},
          %{113 => 16},
          %{114 => 15},
          %{115 => 14},
          %{116 => 8}
        ],
        2,
        algorithm: :cheeky_switcher
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 101, 2 => 104},
             deviation: 0,
             ratings: %{1 => 184, 2 => 184},
             team_groups: %{
               1 => [
                 %{count: 1, group_rating: 51, members: [101], ratings: [51]},
                 %{count: 1, group_rating: 29, members: [106], ratings: [29]},
                 %{count: 1, group_rating: 27, members: [108], ratings: [27]},
                 %{count: 1, group_rating: 25, members: [110], ratings: [25]},
                 %{count: 1, group_rating: 19, members: [112], ratings: [19]},
                 %{count: 1, group_rating: 15, members: [114], ratings: [15]},
                 %{count: 1, group_rating: 10, members: [102], ratings: [10]},
                 %{count: 1, group_rating: 8, members: [116], ratings: [8]}
               ],
               2 => [
                 %{count: 1, group_rating: 35, members: [104], ratings: '#'},
                 %{count: 1, group_rating: 34, members: [105], ratings: [34]},
                 %{count: 1, group_rating: 28, members: [107], ratings: [28]},
                 %{count: 1, group_rating: 26, members: [109], ratings: [26]},
                 %{count: 1, group_rating: 21, members: [111], ratings: [21]},
                 %{count: 1, group_rating: 16, members: [113], ratings: [16]},
                 %{count: 1, group_rating: 14, members: [115], ratings: [14]},
                 %{count: 1, group_rating: 10, members: [103], ratings: '\n'}
               ]
             },
             team_players: %{1 => 'ejlnprft', 2 => 'hikmoqsg'},
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 23.0, 2 => 23.0},
             stdevs: %{1 => 12.816005617976296, 2 => 8.674675786448736}
           }
  end

  # @tag runnable: true
  test "cheeky_switcher: stacked groups" do
    result =
      BalanceLib.create_balance(
        [
          %{101 => 11, 102 => 10, 103 => 10, 104 => 35},
          %{110 => 25, 111 => 21, 112 => 19, 113 => 16},
          %{114 => 15, 115 => 14, 116 => 8},

          %{105 => 34},
          %{106 => 29},
          %{107 => 28},
          %{108 => 27},
          %{109 => 26},
        ],
        2,
        algorithm: :cheeky_switcher
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 101, 2 => 104},
             deviation: 0,
             ratings: %{1 => 184, 2 => 184},
             team_groups: %{
               1 => [
                 %{count: 1, group_rating: 51, members: [101], ratings: [51]},
                 %{count: 1, group_rating: 29, members: [106], ratings: [29]},
                 %{count: 1, group_rating: 27, members: [108], ratings: [27]},
                 %{count: 1, group_rating: 25, members: [110], ratings: [25]},
                 %{count: 1, group_rating: 19, members: [112], ratings: [19]},
                 %{count: 1, group_rating: 15, members: [114], ratings: [15]},
                 %{count: 1, group_rating: 10, members: [102], ratings: [10]},
                 %{count: 1, group_rating: 8, members: [116], ratings: [8]}
               ],
               2 => [
                 %{count: 1, group_rating: 35, members: [104], ratings: '#'},
                 %{count: 1, group_rating: 34, members: [105], ratings: [34]},
                 %{count: 1, group_rating: 28, members: [107], ratings: [28]},
                 %{count: 1, group_rating: 26, members: [109], ratings: [26]},
                 %{count: 1, group_rating: 21, members: [111], ratings: [21]},
                 %{count: 1, group_rating: 16, members: [113], ratings: [16]},
                 %{count: 1, group_rating: 14, members: [115], ratings: [14]},
                 %{count: 1, group_rating: 10, members: [103], ratings: '\n'}
               ]
             },
             team_players: %{1 => 'ejlnprft', 2 => 'hikmoqsg'},
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 23.0, 2 => 23.0},
             stdevs: %{1 => 12.816005617976296, 2 => 8.674675786448736}
           }
  end

  # @tag runnable: true
  test "loser_picks: stacked groups" do
    result =
      BalanceLib.create_balance(
        [
          %{101 => 11, 102 => 10, 103 => 10, 104 => 35},
          %{110 => 25, 111 => 21, 112 => 19, 113 => 16},
          %{114 => 15, 115 => 14, 116 => 8},

          %{105 => 34},
          %{106 => 29},
          %{107 => 28},
          %{108 => 27},
          %{109 => 26},
        ],
        2,
        algorithm: :loser_picks
      )

    assert Map.drop(result, [:logs, :time_taken]) == %{
             captains: %{1 => 101, 2 => 104},
             deviation: 0,
             ratings: %{1 => 184, 2 => 184},
             team_groups: %{
               1 => [
                 %{count: 1, group_rating: 51, members: [101], ratings: [51]},
                 %{count: 1, group_rating: 29, members: [106], ratings: [29]},
                 %{count: 1, group_rating: 27, members: [108], ratings: [27]},
                 %{count: 1, group_rating: 25, members: [110], ratings: [25]},
                 %{count: 1, group_rating: 19, members: [112], ratings: [19]},
                 %{count: 1, group_rating: 15, members: [114], ratings: [15]},
                 %{count: 1, group_rating: 10, members: [102], ratings: [10]},
                 %{count: 1, group_rating: 8, members: [116], ratings: [8]}
               ],
               2 => [
                 %{count: 1, group_rating: 35, members: [104], ratings: '#'},
                 %{count: 1, group_rating: 34, members: [105], ratings: [34]},
                 %{count: 1, group_rating: 28, members: [107], ratings: [28]},
                 %{count: 1, group_rating: 26, members: [109], ratings: [26]},
                 %{count: 1, group_rating: 21, members: [111], ratings: [21]},
                 %{count: 1, group_rating: 16, members: [113], ratings: [16]},
                 %{count: 1, group_rating: 14, members: [115], ratings: [14]},
                 %{count: 1, group_rating: 10, members: [103], ratings: '\n'}
               ]
             },
             team_players: %{1 => 'ejlnprft', 2 => 'hikmoqsg'},
             team_sizes: %{1 => 8, 2 => 8},
             means: %{1 => 23.0, 2 => 23.0},
             stdevs: %{1 => 12.816005617976296, 2 => 8.674675786448736}
           }
  end

  def simple_teams(teams) do
    teams
    |> Enum.map(fn {_k, groups} ->
      groups
      |> Enum.map(fn group ->
        cond do
          is_list(group.ratings) -> group.ratings
          is_number(group.ratings) -> [group.ratings]
          true -> raise "Invalid ratings: #{inspect(group.ratings)}"
        end
      end)
    end)
  end

  def parties_preserved(original_groups, result_simple_teams) do
    original_parties = original_groups
    |> Enum.filter(fn group -> length(group) > 1 end)

    original_party_count = length(original_parties)

    preserved_parties = result_simple_teams
    |> Stream.flat_map(& &1)
    |> Enum.filter(fn group -> length(group) > 1 end)
    |> Enum.filter(fn group ->
      Enum.find(original_parties, fn party ->
        Enum.all?(party, fn member_ratings ->
          member_ratings in group
        end)
      end)
    end)

    preserved_parties_count = length(preserved_parties)

    "Preserved parties: #{preserved_parties_count} / #{original_party_count}"
  end

  def compare_algorithms(parties, team_count, test_name) do
    party_map_list = parties
    |> Enum.with_index()
    |> Enum.map(fn {party, index} ->
      party
      |> Enum.with_index()
      |> Enum.map(fn {rating, member_index} ->
        {index * 10 + member_index, rating}
      end)
      |> Map.new()
    end)

    IO.inspect(parties, label: "#{test_name} user list", charlists: :as_lists)

    result_loser_picks =
      BalanceLib.create_balance(
        party_map_list,
        team_count,
        algorithm: :loser_picks
      )

    result_cheeky_switcher =
      BalanceLib.create_balance(
        party_map_list,
        team_count,
        algorithm: :cheeky_switcher
      )

    result_brute_force =
      BalanceLib.create_balance(
        party_map_list,
        team_count,
        algorithm: :brute_force
      )

    IO.inspect(%{
      deviation: result_loser_picks.deviation,
      ratings: result_loser_picks.ratings,
      means: result_loser_picks.means,
      stdevs: result_loser_picks.stdevs,
      time_taken: result_loser_picks.time_taken,
      team_groups: simple_teams(result_loser_picks.team_groups),
      parties: parties_preserved(parties, simple_teams(result_loser_picks.team_groups)),
      # team_groups_full: result_loser_picks.team_groups,
      # logs: result_loser_picks.logs
    }, label: "#{test_name}: loser_picks", charlists: :as_lists)

    IO.inspect(result_cheeky_switcher.logs, label: "#{test_name}: cheeky_switcher logs", charlists: :as_strings)
    IO.inspect(%{
      deviation: result_cheeky_switcher.deviation,
      ratings: result_cheeky_switcher.ratings,
      means: result_cheeky_switcher.means,
      stdevs: result_cheeky_switcher.stdevs,
      time_taken: result_cheeky_switcher.time_taken,
      team_groups: simple_teams(result_cheeky_switcher.team_groups),
      parties: parties_preserved(parties, simple_teams(result_cheeky_switcher.team_groups)),
      # team_groups_full: result_cheeky_switcher.team_groups,
    }, label: "#{test_name}: cheeky_switcher", charlists: :as_lists)

    IO.inspect(%{
      deviation: result_brute_force.deviation,
      ratings: result_brute_force.ratings,
      means: result_brute_force.means,
      stdevs: result_brute_force.stdevs,
      time_taken: result_brute_force.time_taken,
      team_groups: simple_teams(result_brute_force.team_groups),
      parties: parties_preserved(parties, simple_teams(result_brute_force.team_groups)),
    }, label: "#{test_name}: brute_force", charlists: :as_lists)

    assert result_cheeky_switcher.deviation <= result_loser_picks.deviation
    assert Enum.sum(Map.values(result_cheeky_switcher.stdevs)) <= Enum.sum(Map.values(result_loser_picks.stdevs))
    assert result_cheeky_switcher.time_taken <= result_loser_picks.time_taken
    assert result_cheeky_switcher.time_taken <= result_brute_force.time_taken
  end

  @tag runnable: true
  test "Compare algorithms stacked groups" do
    parties = [
      [11, 10, 10, 35],
      [25, 21, 19, 16],
      [15, 14, 8],
      [34],
      [29],
      [28],
      [27],
      [26],
    ]
    compare_algorithms(parties, 2, "stacked groups")
  end

  @tag runnable: true
  test "Compare algorithms MasterBel2 case" do
    parties = [
      [9.39, 15.14],
      [28.84, 15.06],
      [43.69],
      [29.56],
      [28.27],
      [25.34],
      [23.45],
      [21.65],
      [21.6],
      [18.46],
      [17.7],
      [16.29],
      [16.01],
      [10.27]
    ]
    compare_algorithms(parties, 2, "MasterBel2 case")
  end

  # @tag runnable: true
  test "Compare algorithms: team_ffa" do
    parties = [
      [5],
      [6],
      [7],
      [8],
      [9],
      [9]
    ]
    compare_algorithms(parties, 3, "team_ffa")
  end

  @tag runnable: true
  test "Compare algorithms: smurf party" do
    parties = [
       # Our smurf party
      [51, 10, 10],

      # Other players, a range of ratings
      [35],
      [34],
      [29],
      [28],
      [27],
      [26],
      [25],
      [21],
      [19],
      [16],
      [15],
      [14],
      [8]
    ]
    compare_algorithms(parties, 2, "smurf party")
  end

  # @tag runnable: true
  test "Compare algorithms: odd users" do
    parties = [
      [51],
      [10],
      [10],
      [35],
      [34],
      [29],
      [28],
      [27],
      [26],
      [25],
      [21],
      [19],
      [16],
      [15],
      [8]
    ]
    compare_algorithms(parties, 2, "odd users")
  end
end
