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
             stdevs: %{1 => 1.5, 2 => 0.5},
             parties: {0, 0}
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
             stdevs: %{1 => 0.0, 2 => 0.0, 3 => 0.0, 4 => 0.0},
             parties: {0, 0}
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
             stdevs: %{1 => 1.5, 2 => 2.0, 3 => 0.5},
             parties: {0, 0}
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
             stdevs: %{1 => 1.5, 2 => 0.5},
             parties: {1, 1}
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
             stdevs: %{1 => 9.29297449689818, 2 => 8.671072598012312},
             parties: {2, 3}
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
             stdevs: %{1 => 12.816005617976296, 2 => 8.674675786448736},
             parties: {0, 1}
           }
  end

  @tag runnable: false
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
             stdevs: %{1 => 16.015617378046965, 2 => 15.090870584562046},
             parties: {2, 2}
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
             stdevs: %{1 => 16.0312195418814, 2 => 15.074295174236173},
             parties: {2, 2}
           }
  end

  @tag runnable: false
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

    assert Map.drop(result, [:logs, :time_taken, :team_groups, :team_players]) == %{
             captains: %{1 => :gabb, 2 => :eural},
              deviation: 7,
              means: %{1 => 20.5125, 2 => 22.077499999999997},
              ratings: %{1 => 164.1, 2 => 176.61999999999998},
              stdevs: %{1 => 6.531182415918269, 2 => 9.744118418307528},
              team_sizes: %{1 => 8, 2 => 8},
              parties: {2, 2}
           }
  end

  @tag runnable: false
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

    assert Map.drop(result, [:logs, :time_taken, :team_groups, :team_players]) == %{
             captains: %{1 => 108, 2 => 110},
              deviation: 1,
              means: %{1 => 20.625, 2 => 20.375},
              ratings: %{1 => 165, 2 => 163},
              stdevs: %{1 => 8.802520945729126, 2 => 8.335728822364604},
              team_sizes: %{1 => 8, 2 => 8},
              parties: {1, 3}

           }
  end

  @stacked_groups %{
    groups: [ [11, 10, 10, 35], [25, 21, 19, 16], [15, 14, 8],
      [34], [29], [28], [27], [26], ],
    name: "Stacked groups",
    team_count: 2
  }

  @master_bel %{
    groups: [ [9.39, 15.14], [28.84, 15.06], [43.69], [29.56], [28.27],
      [25.34], [23.45], [21.65], [21.6], [18.46], [17.7], [16.29],
      [16.01], [10.27] ],
    name: "MasterBel2 case",
    team_count: 2
  }

  @team_ffa %{
    groups: [ [9.39, 15.14], [28.84, 15.06], [43.69], [29.56], [28.27],
      [25.34], [23.45], [21.65], [21.6], [18.46], [17.7], [16.29],
      [16.01], [10.27] ],
    name: "Team FFA",
    team_count: 3
  }

  @smurf_party %{
    groups: [ [51, 10, 10],
      [35], [34], [29], [28], [27], [26], [25], [21], [19], [16],
      [15], [14], [8] ],
    name: "Smurf party",
    team_count: 2
  }

  @odd_users %{
    groups: [ [51, 10, 10],
      [35], [34], [29], [28], [27], [26], [25], [21], [19], [16],
      [15], [14], [8] ],
    name: "Odd users",
    team_count: 2
  }

  @even_spread %{
    groups: [ [24.42], [23.11], [22.72], [21.01], [20.13], [20.81], [19.78],
      [18.20], [17.10], [16.11], [15.10], [14.08], [13.91], [13.19], [12.1],
      [11.01], ],
    name: "Even spread",
    team_count: 2
  }

  @even_spread_integers %{
    groups: [ [24, 23, 22, 21, 20, 20, 19, 18, 17, 16, 15, 14, 13, 13, 12, 11] ],
    name: "Even spread integers",
    team_count: 2
  }

  @high_low %{
    groups:  [
      [54.42], [43.11], [42.72], [41.01], [30.13], [30.81], [9.78], [8.20],
      [7.10], [6.11], [5.10], [4.08], [3.91], [3.19], [2.1], [1.01], ],
    name: "High low",
    team_count: 2
  }

  @big_lobboy %{
    groups:  [
      [54.42], [43.11], [42.72], [41.01], [30.13], [30.81], [9.78], [8.20],
      [7.10], [6.11], [5.10], [4.08], [3.91], [3.19], [2.1], [1.01], [23.1], [13.1], [24.1], [23.1],
      [13.2], [25.1], [13.2], [2.1, 43.1], [20.1], [19.1], [23.01, 4.1, 23.01, 13.1], [25.1],
      [43.9], [22.1], [14.0], [2.2], [33.1], [13.9], [14.29, 23.7],
      ],
    name: "Big lobby (40)",
    team_count: 2
  }

  @mega_lobby %{
    groups:  [
      [54.42], [43.11], [42.72], [41.01], [30.13], [30.81], [9.78], [8.20],
      [7.10], [6.11], [5.10], [4.08], [3.91], [3.19], [2.1], [1.01], [23.1], [13.1], [24.1], [23.1],
      [13.2], [25.1], [13.2], [2.1], [43.1], [20.1], [19.1], [23.01], [4.1], [23.01], [13.1], [25.1],
      [43.9], [22.1], [14.0], [2.2], [33.1], [13.9], [14.29], [23.7], [2.1], [23.12], [23.19], [23.1],
      [40.9], [21.1], [15.2], [2.8], [33.2], [3.1], [15.2], [23.7], [1.1], [23.21], [33.1], [22.1],
      [41.9], [20], [18], [2.9], [33.9], [33.1], [15.1], [23.8], [2.1], [23.41], [43.1], [21.1],
      [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18],
      ],
    name: "Mega lobby (80)",
    team_count: 2
  }

  @mega_lobby_parties %{
    groups:  [
      [54.42, 43.11], [42.72], [41.01], [30.13, 30.81, 9.78], [8.20],
      [7.10], [6.11], [5.10], [4.08, 3.91, 39.19], [2.1], [1.01], [23.1], [13.1], [24.1, 23.1],
      [13.2, 25.1], [13.2], [2.1], [43.1], [20.1, 19.1, 23.01, 4.1], [23.01], [13.1], [25.1],
      [43.9], [22.1, 14.0, 2.2, 33.1, 13.9], [14.29], [23.7, 2.1], [23.12], [23.19], [23.1],
      [40.9], [21.1, 15.2, 2.8], [33.2], [3.1], [15.2, 23.7, 1.1, 23.21, 33.1], [22.1],
      [41.9], [20], [18], [2.9], [33.9], [33.1], [15.1], [23.8, 2.1, 23.41, 43.1], [21.1],
      [7, 8, 9, 10], [11, 12, 13, 14, 15, 16, 17, 18],
    ],
    name: "Mega lobby, many parties (80)",
    team_count: 2
  }

  # @iterations 1000
  @iterations 100

  @tag runnable: true
  @tag timeout: :infinity
  test "Compare all algorithms against cases" do
    cases = [@stacked_groups, @master_bel, @team_ffa, @smurf_party, @odd_users, @even_spread, @even_spread_integers, @high_low, @mega_lobby, @mega_lobby_parties]
    algorithms = [:cheeky_switcher, :loser_picks, :cheeky_switcher_rating, :cheeky_switcher_smart]
    # cases = [@stacked_groups]
    # algorithms = [:cheeky_switcher_smart]

    results = summarize_average_case_results_per_algorithm(algorithms, cases)

    IO.inspect(results, label: "Results", charlists: :as_lists)
  end

  def summarize_average_case_results_per_algorithm(algorithms, cases) do
    Enum.map(algorithms, fn algorithm ->
      results = Enum.map(cases, fn case_data ->
        res = run_balance_algorithm(case_data, algorithm)
        IO.inspect(res, label: "Result for #{case_data[:name]} with #{algorithm}", charlists: :as_lists)
        res
      end)

      {algorithm, summarize_results(results)}
    end)
  end

  def summarize_results(results) do
    result_count = length(results)
    Enum.reduce(results, %{
      average_deviation: 0,
      average_time: 0,
      parties_preserved: 0,
    }, fn result, acc ->
      %{
        average_deviation: acc.average_deviation + result.deviation / result_count,
        average_time: acc.average_time + result.average_time / result_count,
        parties_preserved: acc.parties_preserved + result.parties[:preserved],
      }
    end)
  end

  def run_balance_algorithm(case_data, algorithm) do
    parties = case_data[:groups]
    team_count = case_data[:team_count]
    case_name = case_data[:name]

    party_map_list = to_party_map_list(parties)

    balancing_result =
      BalanceLib.create_balance(
        party_map_list,
        team_count,
        algorithm: algorithm
      )

    result_time = if @iterations > 0 do
      1..@iterations
        |> Enum.map(fn _ ->
          BalanceLib.create_balance(
            party_map_list,
            team_count,
            algorithm: algorithm
          )
        end)
        |> Enum.map(fn result -> result.time_taken end)
        |> Enum.sum()
    else
      0
    end

    %{
      deviation: balancing_result.deviation,
      ratings: balancing_result.ratings,
      means: balancing_result.means,
      stdevs: balancing_result.stdevs,
      time_taken: balancing_result.time_taken,
      team_groups: simple_teams(balancing_result.team_groups),
      parties: parties_preserved(parties, simple_teams(balancing_result.team_groups)),
      average_time: if @iterations > 0 do result_time / @iterations else 0 end,
    }
  end

  # @tag runnable: false
  # test "Compare algorithms stacked groups" do
  #   compare_algorithm_results(stacked_groups["groups"], stacked_groups["team_count"], stacked_groups["name"])
  #   compare_algorithm_times(stacked_groups["groups"], stacked_groups["team_count"], stacked_groups["name"])
  # end


  # @tag runnable: false
  # test "Compare algorithms MasterBel2 case" do
  #   groups = [ [9.39, 15.14], [28.84, 15.06], [43.69], [29.56], [28.27],
  #     [25.34], [23.45], [21.65], [21.6], [18.46], [17.7], [16.29],
  #     [16.01], [10.27] ]
  #   compare_algorithm_results(groups, 2, "MasterBel2 case")
  #   compare_algorithm_times(groups, 2, "MasterBel2 case")
  # end

  # @tag runnable: false
  # test "Compare algorithms: team_ffa" do
  #   groups = [ [5], [6], [7], [8], [9], [9] ]
  #   compare_algorithm_results(groups, 3, "team_ffa")
  #   compare_algorithm_times(groups, 3, "team_ffa")
  # end

  # @tag runnable: false
  # test "Compare algorithms: smurf party" do
  #   groups = [ [51, 10, 10],
  #     [35], [34], [29], [28], [27], [26], [25], [21], [19], [16],
  #     [15], [14], [8] ]
  #   compare_algorithm_results(groups, 2, "smurf party")
  #   compare_algorithm_times(groups, 2, "smurf party")
  # end

  # @tag runnable: false
  # test "Compare algorithms: odd users" do
  #   groups = [ [51], [10], [10], [35], [34], [29], [28], [27], [26],
  #     [25], [21], [19], [16], [15], [8] ]
  #   compare_algorithm_results(groups, 2, "odd users")
  #   compare_algorithm_times(groups, 2, "odd users")
  # end

  # @tag runnable: true
  # test "Compare algorithms: Even spread" do
  #   groups = [ [24.42], [23.11], [22.72], [21.01], [20.13], [20.81], [19.78],
  #     [18.20], [17.10], [16.11], [15.10], [14.08], [13.91], [13.19], [12.1],
  #     [11.01], ]
  #   compare_algorithm_results(groups, 2, "Even spread")
  #   compare_algorithm_times(groups, 2, "Even spread")
  # end

  # @tag runnable: false
  # test "Compare algorithms: Even spread - itegers" do
  #   groups = [ [24], [23], [22], [21], [20], [20], [19], [18], [17], [16],
  #    [15], [14], [13], [13], [12], [11] ]
  #   compare_algorithm_results(groups, 2, "Even spread - integers")
  #   compare_algorithm_times(groups, 2, "Even spread - integers")
  # end

  # @tag runnable: false
  # test "Compare algorithms: High low" do
  #   groups = [
  #     [54.42], [43.11], [42.72], [41.01], [30.13], [30.81], [9.78], [8.20],
  #     [7.10], [6.11], [5.10], [4.08], [3.91], [3.19], [2.1], [1.01], ]
  #   compare_algorithm_results(groups, 2, "High low")
  #   compare_algorithm_times(groups, 2, "High low")
  # end

  def simple_teams(teams) do
    teams
    |> Enum.map(fn {_k, groups} ->
      groups
      |> Enum.map(fn group ->
        cond do
          is_list(group.ratings) -> group.ratings
          is_number(group.ratings) -> [group.ratings]
          false -> raise "Invalid ratings: #{inspect(group.ratings)}"
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

    %{:preserved => preserved_parties_count,
      :original => original_party_count}
  end

  def to_party_map_list(parties) do
    parties
    |> Enum.with_index()
    |> Enum.map(fn {party, index} ->
      party
      |> Enum.with_index()
      |> Enum.map(fn {rating, member_index} ->
        {index * 10 + member_index, rating}
      end)
      |> Map.new()
    end)
  end

  def run_algorithm_and_print_results(party_map_list, parties, team_count, algorithm, test_name) do
    result_cheeky_switcher =
      BalanceLib.create_balance(
        party_map_list,
        team_count,
        algorithm: algorithm
      )

    IO.inspect(%{
      deviation: result_cheeky_switcher.deviation,
      ratings: result_cheeky_switcher.ratings,
      means: result_cheeky_switcher.means,
      stdevs: result_cheeky_switcher.stdevs,
      time_taken: result_cheeky_switcher.time_taken,
      team_groups: simple_teams(result_cheeky_switcher.team_groups),
      parties: parties_preserved(parties, simple_teams(result_cheeky_switcher.team_groups)),
      # team_groups_full: result_cheeky_switcher.team_groups,
    }, label: "#{test_name}: #{algorithm}", charlists: :as_lists)
  end

  def compare_algorithm_results(parties, team_count, test_name) do
    party_map_list = to_party_map_list(parties)

    IO.inspect(parties, label: "\nCompare timings: #{test_name}", charlists: :as_lists)

    run_algorithm_and_print_results(
      party_map_list,
      parties,
      team_count,
      :cheeky_switcher,
      test_name)

    run_algorithm_and_print_results(
      party_map_list,
      parties,
      team_count,
      :cheeky_switcher_rating,
      test_name)

    run_algorithm_and_print_results(
      party_map_list,
      parties,
      team_count,
      :cheeky_switcher_smart,
      test_name)

    run_algorithm_and_print_results(
      party_map_list,
      parties,
      team_count,
      :loser_picks,
      test_name)

    # Commented out because it is slooow, but sometimes useful for debugging
    # when looking for an optimal result
    # run_algorithm_and_print_results(party_map_list, team_count, :brute_force, test_name)
  end

  def compare_algorithm_times(parties, team_count, test_name) do
    party_map_list = to_party_map_list(parties)

    IO.inspect(parties, label: "\nCompare results: #{test_name}", charlists: :as_lists)

    iterations = 10000

    result_loser_picks_time = 1..iterations
      |> Enum.map(fn _ ->
        BalanceLib.create_balance(
          party_map_list,
          team_count,
          algorithm: :loser_picks
        )
      end)
      |> Enum.map(fn result -> result.time_taken end)
      |> Enum.sum()

    result_cheeky_switcher_time = 1..iterations
      |> Enum.map(fn _ ->
        BalanceLib.create_balance(
          party_map_list,
          team_count,
          algorithm: :cheeky_switcher
        )
      end)
      |> Enum.map(fn result -> result.time_taken end)
      |> Enum.sum()

    result_cheeky_switcher_rating_time = 1..iterations
      |> Enum.map(fn _ ->
        BalanceLib.create_balance(
          party_map_list,
          team_count,
          algorithm: :cheeky_switcher_rating
        )
      end)
      |> Enum.map(fn result -> result.time_taken end)
      |> Enum.sum()

    result_cheeky_switcher_smart_time = 1..iterations
      |> Enum.map(fn _ ->
        BalanceLib.create_balance(
          party_map_list,
          team_count,
          algorithm: :cheeky_switcher_smart
        )
      end)
      |> Enum.map(fn result -> result.time_taken end)
      |> Enum.sum()

    IO.inspect(%{
      loser_picks_time: result_loser_picks_time / iterations,
      cheeky_switcher_time: result_cheeky_switcher_time / iterations,
      cheeky_switcher_rating_time: result_cheeky_switcher_rating_time / iterations,
      cheeky_switcher_smart_time: result_cheeky_switcher_smart_time / iterations
    })
  end
end
