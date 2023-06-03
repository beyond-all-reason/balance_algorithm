defmodule Teiserver.Battle.BruteForceAlgorithm do
  import Teiserver.Battle.BalanceUtil

  @max_switches 3

  @type expanded_group_or_pair :: BalanceUtils.expanded_group_or_pair
  @type team_map :: BalanceUtils.team_map
  @type group_list :: [expanded_group_or_pair()]


  def brute_force_dont_use_in_production_for_the_love_of_bar(expanded_groups, team_count, opts \\ [])
  def brute_force_dont_use_in_production_for_the_love_of_bar(expanded_groups, team_count, opts) do
    brute_force_dont_use_in_production_for_the_love_of_bar(expanded_groups, team_count, opts, [])
  end
  def brute_force_dont_use_in_production_for_the_love_of_bar([], _team_count, _opts, _log) do
    {[], []}
  end
  def brute_force_dont_use_in_production_for_the_love_of_bar(expanded_groups, team_count, _opts, log) do
    # We're going to brute force all possible combinations of teams
    # and then pick the best one
    # This is a very dumb approach and will be slow for large groups
    # but it's a good point of comparison for the other algorithms

    team_member_size = ceil(sum_group_membership_size(expanded_groups) / team_count)

    team_alternatives = expanded_groups
    |> make_group_combinations(team_member_size)
    |> Enum.map(fn team ->
      Enum.map(team, fn {group, _i} -> group end)
    end)
    |> Enum.with_index()
    |> make_list_of_team_combinations(team_count)
    |> Enum.sort_by(fn team -> team[:score] end, :asc)
    |> Enum.take(3)

    {hd(team_alternatives).team_groups, log}
  end

  @spec make_list_of_team_combinations([{any, any}], any) :: any
  def make_list_of_team_combinations(team_candidates, team_count) do make_list_of_team_combinations(team_candidates, team_count, []) end
  @spec make_list_of_team_combinations([{any, any}], any, any) :: any
  def make_list_of_team_combinations([], _team_count, teams) do teams end
  def make_list_of_team_combinations([first_candidate | rest_candidates], team_count, teams) do
    {first_candidate, idx} = first_candidate
    # Combine two and two groups into a team
    # This is a recursive function that will combine all groups into teams
    # and then return a list of all possible combinations of teams
    # The result is a list of lists of teams
    # Example:
    #   [[team1, team2], [team3, team4], [team5, team6]]
    #   [[team1, team2, team3], [team4, team5, team6]]

    valid_candidates = rest_candidates
    |> Enum.map(fn {second_team, _i} ->
      if has_overlapping_members(first_candidate, second_team) do
        nil
      else
        team_groups =  %{
          1 => first_candidate,
          2 => second_team,
        }
        deviation = max_team_rating_difference(team_groups)
        stdevs = team_stddevs(team_groups)
        score = deviation * 10 + Enum.max(stdevs)
        %{
          deviation: deviation,
          ratings: team_ratings(team_groups),
          means: team_means(team_groups),
          stdevs: stdevs,
          score: score,
          team_groups: team_groups,
        }
      end
    end)
    |> Enum.filter(fn x -> x != nil end)
    make_list_of_team_combinations(rest_candidates, team_count, teams ++ valid_candidates)
  end

  defp has_overlapping_members(group1, group2) do
    group1
    |> Enum.flat_map(fn group -> group.members end)
    |> Enum.any?(fn member ->
      group2
      |> Enum.flat_map(fn group -> group.members end)
      |> Enum.any?(fn other_member -> member == other_member end)
    end)
  end
end
