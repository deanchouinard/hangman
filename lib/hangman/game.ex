defmodule Hangman.Game do

  defstruct(
    turns_left: 7,
    game_state: :initializing,
    letters: [],
    used: MapSet.new(),
  )

  @doc """
  Interestinng technique; you can either provide a word or have the system
  automatically generate on for you using the same function.
  """
  def new_game(word) do
    %Hangman.Game{ letters: word |> String.codepoints }
  end

  def new_game() do
    new_game(Dictionary.random_word())
  end

  def make_move(game = %{ game_state: state }, _guess) when state in [:won, :lost] do
     game
  end

  def make_move(game, guess) do
    valid_guess?(game, guess, Regex.match?(~r/^[a-z]{1}$/, guess))
  end

  def tally(game) do
    %{
      game_state: game.game_state,
      turns_left: game.turns_left,
      letters: game.letters |> reveal_guessed(game.used)
    }
  end

  #########################

  # An iteresting technique here. Because you cannot do a boolena test
  # and pattern match
  # in the function call to find out if the guess has already occured,
  # call another function, in this case accept_move, that performs
  # a boolean test and pattern match on that function definition.
  defp valid_guess?(game, guess, _valid_guess = true) do
    accept_move(game, guess, MapSet.member?(game.used, guess))
  end

  defp valid_guess?(game, guess, _invalid_guess) do
    game
  end

  defp accept_move(game, guess, _already_guessed = true) do
    Map.put(game, :game_state, :already_used)
  end

  defp accept_move(game, guess, _already_guessed) do
    Map.put(game, :used, MapSet.put(game.used, guess))
    |> score_guess(Enum.member?(game.letters, guess))
  end

  # Another good technique below. The MapSet.subset? function does a test.
  # Instead of some kind of conditional statement to process the result,
  # the result is fed into another function that uses patter matching to
  # perform the appropriate processing.
  #
  # Also, rather than just using a ture or false in the function signature,
  # it is matched to a descriptive variable name.
  defp score_guess(game, _good_guess = true) do
    new_state = MapSet.new(game.letters)
                |> MapSet.subset?(game.used)
                |> maybe_won()
    Map.put(game, :game_state, new_state)
  end

  defp score_guess(game = %{ turns_left: 1 }, _not_good_guess) do
    Map.put(game, :game_state, :lost)
  end

  defp score_guess(game = %{ turns_left: turns_left }, _not_good_guess) do
    %{ game |
      game_state: :bad_guess,
      turns_left: turns_left - 1
    }
  end

  # Another example of putting a boolean test in a function invocation
  # and using pattern matching to process the decision.
  
  defp reveal_guessed(letters, used) do
    letters
    |> Enum.map(fn letter -> reveal_letter(letter, MapSet.member?(used, letter)) end)
  end

  defp reveal_letter(letter, _in_word = true), do: letter
  defp reveal_letter(letter, _not_in_word), do: "_"

  defp maybe_won(true), do: :won
  defp maybe_won(_),    do: :good_guess

end
