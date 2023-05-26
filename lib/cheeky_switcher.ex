defmodule Teiserver.Battle.CheekySwitcherAlgorithm do
  import Teiserver.Battle.BalanceUtil

  @max_switches 3

  @type expanded_group_or_pair :: BalanceUtils.expanded_group_or_pair
  @type team_map :: BalanceUtils.team_map
  @type group_list :: [expanded_group_or_pair()]

  def acceptable_teams(teams) do
    max_team_rating_difference(teams) < 5
  end

  def cheeky_switcher([], _team_count, _opts) do
    {[], []}
  end

  @spec cheeky_switcher(group_list(), number(), list()) :: {team_map(), list()}
  @spec cheeky_switcher(
          [%{count: non_neg_integer, group_rating: float, members: list, ratings: [float]}],
          number
        ) :: {[] | %{optional(any) => list}, list}
  def cheeky_switcher(expanded_groups, team_count) do cheeky_switcher(expanded_groups, team_count, []) end
  def cheeky_switcher(expanded_groups, team_count, log) do
    {teams, log} = expanded_groups
    |> sort_groups_by_rating()
    |> IO.inspect(label: "Sorted by rating", charlists: :as_lists)
    |> place_groups_to_smallest_teams(make_empty_teams(team_count), log)
    |> IO.inspect(label: "Placed groups", charlists: :as_lists)
    |> switch_best_rating_diffs()
    |> IO.inspect(label: "Switched all groups, exiting", charlists: :as_lists)

    parties_left = count_parties_in_teams(teams)

    if acceptable_teams(teams) or parties_left <= 0 do
      {teams, log}
    else
      cheeky_switcher(
        teams_to_groups_without_largest_party(teams),
        team_count,
        log ++ ["Unacceptable rating difference of #{max_team_rating_difference(teams)} with current parties, retrying without largest party"])
    end
  end

  # End if the teams are even or if we've switched too many times
  @spec switch_best_rating_diffs({team_map(), list()}) :: {team_map(), list()}
  defp switch_best_rating_diffs({teams, log}) do
    team_rating_diff = max_team_rating_difference(teams)
    IO.inspect(teams, label: "Team rating diff #{team_rating_diff}", charlists: :as_lists)

    if team_rating_diff == 0 do
      {teams, log ++ ["Teams already balanced"]}
    else
      # Since switching two groups will lower one team and raise the other,
      # We aim to find a pair that has a rating difference of half the total
      equalizing_diff = team_rating_diff / 2

      # Find the best pair of groups to switch between the lowest ranked team
      # and highest ranked team
      case find_best_pair_to_switch(teams, equalizing_diff) do
        %{
          highest_team_id: nil,
          highest_team_combo: [],
          lowest_team_id: nil,
          lowest_team_combo: [],
          best_diff: :infinity
        } ->
          # No pair found, so we can't switch any more
          {teams, log ++ ["No good switch options found."]}
        %{
          highest_team_id: highest_team_id,
          highest_team_combo: highest_team_combo,
          lowest_team_combo: lowest_team_combo,
          lowest_team_id: lowest_team_id,
          combo_switch_diff: combo_switch_diff,
          best_diff: best_diff
        } ->
          lowest_combo_indices = lowest_team_combo
            |> Enum.map(fn {_g, i} -> to_string(i) end)
            |> Enum.join(", ")

          highest_combo_indices = highest_team_combo
            |> Enum.map(fn {_g, i} -> to_string(i) end)
            |> Enum.join(", ")

          # Found a pair, so switch them
          IO.inspect(
            %{
              highest_team_id: highest_team_id,
              highest_team_combo: highest_team_combo,
              lowest_team_id: lowest_team_id,
              lowest_team_combo: lowest_team_combo,
              combo_switch_diff: combo_switch_diff,
              best_diff: best_diff,
              teams: teams,
              highest_combo_indices: highest_combo_indices,
              lowest_combo_indices: lowest_combo_indices,
            },
            label: "Best pair to switch",
            charlists: :as_lists)

          # Switch the best pair
          {switch_group_combos_between_teams(
            teams,
            highest_team_id,
            highest_team_combo,
            lowest_team_id,
            lowest_team_combo
          ),
          log ++ ["Switched groups #{highest_combo_indices} from team #{highest_team_id} with groups #{lowest_combo_indices} from team #{lowest_team_id}"]}
      end
    end
  end

  # Find a pair of groups from the lowest ranked team and highest ranked team
  # that have a rating difference close to equalizing_diff
  @spec find_best_pair_to_switch(team_map(), non_neg_integer()) :: map()
  defp find_best_pair_to_switch(teams, equalizing_diff) do
    {{lowest_team_id, rating_l}, {highest_team_id, rating_h}} = lowest_highest_rated_teams(teams)
    highest_team_groups = teams[highest_team_id]
    lowest_team_groups = teams[lowest_team_id]
    IO.inspect("Highest team #{highest_team_id}: #{rating_h}, lowest team #{lowest_team_id}: #{rating_l}. Equalizing diff: #{equalizing_diff}", label: "Finding best pair to switch")

    biggest_group_size = highest_team_groups
      |> Enum.map(fn group -> group.count end)
      |> Enum.max()

    highest_team_groups_combos = make_group_combinations(
      highest_team_groups,
      biggest_group_size,
      true)

    # Find the pair of groups that are closest to the equalizing_diff
    Enum.reduce(
      highest_team_groups_combos,
      %{
        highest_team_id: nil,
        highest_team_combo: [],
        lowest_team_id: nil,
        lowest_team_combo: [],
        best_diff: :infinity
      },
      fn highest_team_combo, best_pair ->
        # IO.inspect(highest_team_combo, label: "Highest team group combo", charlists: :as_lists)
        highest_team_combo_count = Enum.reduce(highest_team_combo, 0,
          fn {group, _i}, acc -> acc + group.count end)
        highest_combo_rating = Enum.reduce(highest_team_combo, 0,
          fn {group, _i}, acc -> acc + group.group_rating end)

        # make matching groups that can be switched with. In this format:
        # [
        #  [{group1, 1}, {group2, 2}, {group3, 3}],
        #  [{group1, 2}, {group4, 4}], # group 4 has 2 members
        #  [{group2, 2}, {group3, 3}, {group5, 5}],
        #  ...etc for all combinations of groups with the same number of members
        # ]
        lowest_team_groups_combos = make_group_combinations(
          lowest_team_groups,
          highest_team_combo_count)

        Enum.reduce(
          lowest_team_groups_combos,
          best_pair,
          fn combo, best_pair_inner ->
            %{best_diff: best_diff} = best_pair_inner

            combo_members = Enum.reduce(combo, 0,
              fn {group, _i}, acc -> acc + group.count end)
            combo_rating = Enum.reduce(combo, 0,
              fn {group, _i}, acc -> acc + group.group_rating end)

            if highest_team_combo_count != combo_members do
              # The groups are not the same size, so we can't switch them
              best_pair_inner
            else
              combo_switch_diff = highest_combo_rating - combo_rating
              # diff_from_equalizing = combo_switch_diff - equalizing_diff
              diff_from_equalizing = abs(combo_switch_diff - equalizing_diff)

              # IO.inspect(%{
              #   combo: combo,
              #   highest_team_combo: highest_team_combo,
              #   combo_members: combo_members,
              #   combo_rating: combo_rating,
              #   combo_switch_diff: combo_switch_diff,
              #   diff_from_equalizing: diff_from_equalizing,
              #   best_diff: best_diff
              # }, label: "matchup", charlists: :as_lists)

              if diff_from_equalizing < best_diff do
                %{
                  highest_team_id: highest_team_id,
                  highest_team_combo: highest_team_combo,
                  lowest_team_id: lowest_team_id,
                  lowest_team_combo: combo,
                  best_diff: diff_from_equalizing,
                  combo_switch_diff: combo_switch_diff
                }
              else
                best_pair_inner
              end
            end
          end)
      end)
  end

  @spec place_groups_to_smallest_teams(group_list(), team_map(), list()) :: {team_map(), list()}
  defp place_groups_to_smallest_teams([], teams, log) do
    team_member_diff = max_team_member_count_difference(teams)
    case team_member_diff do
      0 -> {teams, log}
      1 -> {teams, log}
      _ ->
        IO.inspect(teams, label: "Teams are not even (#{team_member_diff}), breaking up largest party", charlists: :as_lists)
        # Break up the biggest party (there has to be a party) that obstructs
        # making equal teams and restart grouping, which now should be easier to get even.
        place_groups_to_smallest_teams(
          teams_to_groups_without_largest_party(teams),
          make_empty_teams(map_size(teams)),
          log ++ ["Teams are not even, breaking up largest party"]
        )
    end
  end

  defp place_groups_to_smallest_teams([next_group | rest_groups], teams, log) do
    team_key = find_smallest_team_key(teams);
    place_groups_to_smallest_teams(
      rest_groups,
      add_group_to_team(teams, next_group, team_key),
      log ++ ["Added #{next_group.count} members with total rating of #{next_group.group_rating} to team #{team_key}"])
  end

  @spec teams_to_groups_without_largest_party(map()) :: group_list()
  defp teams_to_groups_without_largest_party(teams) do
    teams
    # Return to the list of groups
    |> unwind_teams_to_groups()
    # Sort by party size
    |> sort_groups_by_count()
    # Break up the first and largest party
    |> break_up_first_party()
    # Sort again by rating
    |> sort_groups_by_rating()
  end

  defp break_up_first_party([]) do
    []
  end

  defp break_up_first_party([group | rest_groups]) do
    rest_groups ++ Enum.map(Enum.with_index(group.members),
      fn {member_id, i} -> %{count: 1, group_rating: Enum.at(group.ratings, i), ratings: Enum.at(group.ratings, i), members: [member_id]} end)
  end

  @spec add_group_to_team(team_map(), expanded_group_or_pair(), atom()) :: team_map()
  defp add_group_to_team(teams, group, team_key) do
    Map.update!(teams, team_key, fn members -> members ++ [group] end)
  end

  @spec find_smallest_team_key(team_map()) :: atom()
  defp find_smallest_team_key(teams) do
    Enum.min_by(
      teams,
      fn {_k, team_groups} -> case length(team_groups) do
        0 -> 0
        _ -> sum_group_membership_size(team_groups)
      end
    end)
    |> elem(0)
  end
end
