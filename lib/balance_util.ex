defmodule Teiserver.Battle.BalanceUtil do
  @moduledoc """
  Documentation for BalanceUtil.
  """

  alias Central.Config

  # Upper boundary is how far above the group value the members can be, lower is how far below it
  # these values are in general used for group pairing where we look at making temporary groups on
  # each team to make the battle fair
  @rating_lower_boundary 3
  @rating_upper_boundary 5

  @mean_diff_max 5
  @stddev_diff_max 3

  # Fuzz multiplier is used by the BalanceServer to prevent two games being completely identical
  # teams. It is defaulted here as the server uses this library to get defaults
  @fuzz_multiplier 0.5

  # When set to true, if there are any teams with 0 points (first pick) it randomises
  # which one will get to pick first
  @shuffle_first_pick true

  @type rating_value() :: float()
  @type player_group() :: %{T.userid() => rating_value()}
  @type expanded_group() :: %{
          members: [T.userid()],
          ratings: [rating_value()],
          group_rating: rating_value(),
          count: non_neg_integer()
        }
  @type expanded_group_or_pair() :: expanded_group() | {expanded_group(), expanded_group()}
  @type team_map() :: %{T.team_id() => [expanded_group()]}

  # These are default values and can be overridden as part of the call to create_balance()
  @spec defaults() :: map()
  def defaults() do
    %{
      max_deviation: Config.get_site_config_cache("teiserver.Max deviation"),
      rating_lower_boundary: @rating_lower_boundary,
      rating_upper_boundary: @rating_upper_boundary,
      mean_diff_max: @mean_diff_max,
      stddev_diff_max: @stddev_diff_max,
      fuzz_multiplier: @fuzz_multiplier,
      shuffle_first_pick: @shuffle_first_pick
    }
  end

  # Given a list of groups, return the combined number of members
  @spec sum_group_membership_size([expanded_group()]) :: non_neg_integer()
  def sum_group_membership_size([]), do: 0

  def sum_group_membership_size(groups) do
    groups
    |> Enum.map(fn %{count: count} -> count end)
    |> Enum.sum()
  end

  # Given a list of groups, return the combined rating (summed)
  @spec sum_group_rating([expanded_group()]) :: non_neg_integer()
  def sum_group_rating([]), do: 0

  def sum_group_rating(groups) do
    groups
    |> Enum.map(fn %{group_rating: group_rating} -> group_rating end)
    |> Enum.sum()
  end

  @spec min_max_difference([non_neg_integer()]) :: non_neg_integer()
  def min_max_difference(list) do
    Enum.max(list) - Enum.min(list)
  end

  @spec max_team_member_count_difference(team_map()) :: non_neg_integer()
  def max_team_member_count_difference(teams) do
    teams
    |> Enum.map(fn {_k, team_groups} -> sum_group_membership_size(team_groups) end)
    |> min_max_difference()
  end

  @spec max_team_rating_difference(team_map()) :: non_neg_integer()
  def max_team_rating_difference(teams) do
    teams
    |> Enum.map(fn {_k, team_groups} -> sum_group_rating(team_groups) end)
    |> min_max_difference()
  end

  @spec make_empty_teams(non_neg_integer()) :: team_map()
  def make_empty_teams(team_count) do
    Range.new(1, team_count)
      |> Map.new(fn i ->
        {i, []}
      end)
  end

  @spec sort_groups_by_rating([expanded_group()]) :: [expanded_group()]
  def sort_groups_by_rating(groups) do
    Enum.sort_by(
      groups,
      fn %{group_rating: rating} -> rating end,
      :desc)
  end

  @spec sort_groups_by_count([expanded_group()]) :: [expanded_group()]
  def sort_groups_by_count(groups) do
    Enum.sort_by(
      groups,
      fn %{count: count} -> count end,
      :desc)
  end

  @spec unwind_teams_to_groups(team_map()) :: [expanded_group()]
  def unwind_teams_to_groups(teams) do
    Enum.flat_map(teams, fn {_k, team_groups} -> team_groups end)
  end

  @spec has_parties(team_map()) :: boolean()
  def has_parties(teams) do
    teams
    |> Enum.any?(fn {_k, team_groups} ->
      Enum.any?(team_groups, fn %{count: count} -> count > 1 end) end)
  end

  @spec replace_team_group_at_index(team_map(), T.team_id(), non_neg_integer(), expanded_group()) :: team_map()
  def replace_team_group_at_index(teams, team_id, group_index, group) do
    Map.put(teams, team_id, List.replace_at(teams[team_id], group_index, group))
  end

  @spec switch_group_pair_between_teams(team_map(), T.team_id(), non_neg_integer(), T.team_id(), non_neg_integer()) :: team_map()
  def switch_group_pair_between_teams(
    teams,
    team_a_id,
    group_a_index,
    group_b_id,
    group_b_index) do
    team_a_groups = teams[team_a_id]
    group_a = Enum.at(team_a_groups, group_a_index)
    team_b_groups = teams[group_b_id]
    group_b = Enum.at(team_b_groups, group_b_index)

    replace_team_group_at_index(teams, team_a_id, group_a_index, group_b)
    |> replace_team_group_at_index(group_b_id, group_b_index, group_a)
  end

  @spec lowest_highest_rated_teams(team_map()) :: {{T.team_id(), non_neg_integer()}, {T.team_id(), non_neg_integer()}}
  def lowest_highest_rated_teams(teams) do
    teams
    |> IO.inspect()
    |> Enum.map(fn {team_id, team_groups} ->
      {team_id, sum_group_rating(team_groups)}
    end)
    |> IO.inspect()
    |> Enum.min_max_by(fn {_team_id, rating} -> rating end)
  end
end
