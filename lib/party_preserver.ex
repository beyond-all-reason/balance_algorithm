defmodule Teiserver.Battle.PartyPreserverAlgorithm do
  import Teiserver.Battle.BalanceUtil

  @max_switches 3

  @type expanded_group_or_pair :: BalanceUtils.expanded_group_or_pair
  @type team_map :: BalanceUtils.team_map
  @type group_list :: [expanded_group_or_pair()]

  def party_preserver([], _team_count, _opts) do
    {[], []}
  end

  @spec party_preserver(group_list(), number(), list()) :: {team_map(), list()}
  def party_preserver(expanded_groups, team_count, _opts) do
    expanded_groups
    |> sort_groups_by_rating()
    |> IO.inspect(label: "Sorted by rating")
    |> place_groups_to_smallest_teams(make_empty_teams(team_count), [])
    |> IO.inspect(label: "Placed groups")
    |> start_switch_best_rating_diffs()
    |> IO.inspect(label: "Switched all groups, exiting")
  end

  @spec start_switch_best_rating_diffs({team_map(), list()}) :: {team_map(), list()}
  defp start_switch_best_rating_diffs({teams, log}) do
    switch_best_rating_diffs(teams, log)
  end

  # End if the teams are even or if we've switched too many times
  @spec switch_best_rating_diffs(team_map(), non_neg_integer(), list()) :: {team_map(), list()}
  defp switch_best_rating_diffs(teams, log) do switch_best_rating_diffs(teams, log, 0) end
  defp switch_best_rating_diffs(teams, log, i) when i >= @max_switches do
    {teams, log}
  end

  defp switch_best_rating_diffs(teams, log, i) when i < @max_switches do
    team_rating_diff = max_team_rating_difference(teams)
    IO.inspect(teams, label: "Team rating diff #{team_rating_diff}")
    if team_rating_diff < 2 do
      {teams, log ++ ["Found a good balance of #{team_rating_diff} after #{i} switches"]}
    else
      # Since switching two groups will lower one team and raise the other,
      # We aim to find a pair that has a rating difference of half the total
      equalizing_diff = team_rating_diff / 2

      # Find the best pair of groups to switch between the lowest ranked team
      # and highest ranked team
      %{
        highest_team_id: highest_team_id,
        highest_group_index: highest_group_index,
        lowest_team_id: lowest_team_id,
        lowest_group_index: lowest_group_index,
        rating_diff: rating_diff,
        best_diff: best_diff
      } = find_best_pair_to_switch(teams, equalizing_diff)

      IO.inspect(
        %{
          highest_team_id: highest_team_id,
          highest_group_index: highest_group_index,
          lowest_team_id: lowest_team_id,
          lowest_group_index: lowest_group_index,
          rating_diff: rating_diff,
          best_diff: best_diff,
          teams: teams
        },
        label: "Best pair to switch")

      # Switch the best pair
      switch_best_rating_diffs(
        switch_group_pair_between_teams(
          teams,
          highest_team_id,
          highest_group_index,
          lowest_team_id,
          lowest_group_index
        ),
        log ++ ["Switched group #{highest_group_index} from team #{highest_team_id} with group #{lowest_group_index} from team #{lowest_team_id}"],
        i + 1)
    end
  end

  # Find a pair of groups from the lowest ranked team and highest ranked team
  # that have a rating difference close to equalizing_diff
  @spec find_best_pair_to_switch(team_map(), non_neg_integer()) :: map()
  defp find_best_pair_to_switch(teams, equalizing_diff) do
    {{lowest_team_id, rating_l}, {highest_team_id, rating_h}} = lowest_highest_rated_teams(teams)
    highest_team_groups = teams[highest_team_id]
    lowest_team_groups = teams[lowest_team_id]
    IO.inspect("Highest team #{highest_team_id}: #{rating_h}, lowest: #{lowest_team_id}, #{rating_l}")

    # Find the pair of groups that are closest to the equalizing_diff
    Enum.reduce(
      Enum.with_index(highest_team_groups),
      %{
        highest_team_id: nil,
        highest_group_index: nil,
        lowest_team_id: nil,
        lowest_group_index: nil,
        best_diff: :infinity
      },
      fn {highest_group, highest_group_index}, best_pair ->
        Enum.reduce(
          Enum.with_index(lowest_team_groups),
          best_pair,
          fn {lowest_group, lowest_group_index}, best_pair_inner ->
            if highest_group.count != lowest_group.count do
              # The groups are not the same size, so we can't switch them
              best_pair_inner
            else
              %{best_diff: best_diff} = best_pair_inner

              rating_diff = highest_group.group_rating - lowest_group.group_rating
              pair_equalizing_diff = abs(rating_diff - equalizing_diff)

              if pair_equalizing_diff < best_diff do
                %{
                  highest_team_id: highest_team_id,
                  highest_group_index: highest_group_index,
                  lowest_team_id: lowest_team_id,
                  lowest_group_index: lowest_group_index,
                  best_diff: pair_equalizing_diff,
                  rating_diff: rating_diff
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
        IO.inspect(teams, label: "Teams are not even (#{team_member_diff}), breaking up largest party")
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
    rest_groups ++ Enum.map(group.members,
      fn member -> %{count: 1, group_rating: member, members: [member]} end)
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
