class GamesController < ApplicationController
  require "open-uri"
  require "json"
  require "time"

  def new
    # Create a new array of 10 random letters from A-Z
    # Store these letters in @letters (for view display)
    # Save these letters in session[:grid] to keep track across requests
    # Save the current time in session[:start_time] to measure elapsed time later
    @letters = Array.new(10) { ("A".."Z").to_a.sample }
    session[:grid] = @letters
    session[:start_time] = Time.now
  end

  def score
    # Get the word submitted by the user from the form (params[:userAnswer])
    # Retrieve the previously stored grid from the session
    # Retrieve the start time from the session and convert it back to a Time object
    # Record the current time as end_time
    # Calculate how many seconds the user took (end_time - start_time)
    # Run the main game logic to check validity and compute the score
    @attempt = params[:userAnswer]
    @grid = session[:grid]
    start_time = session[:start_time] ? Time.parse(session[:start_time]) : Time.now
    end_time = Time.now

    # Calculate time spent
    time_taken = end_time - start_time

    # Run the game logic and get the result (score, message, time)
    @result = run_game(@attempt, @grid, time_taken)
  end

  private

  def included?(guess, grid)
    # Convert the guess into an array of letters
    # Check if ALL letters in guess appear in the grid
    # and do not exceed the number of times they appear in the grid
    guess.chars.all? { |letter| guess.count(letter) <= grid.count(letter) }
  end

  def compute_score(attempt, time_taken)
    #  If the user took more than 60 seconds, score is 0
    #  Otherwise, score = length of word * (1 - (time_taken / 60))
    #  penalizes longer time
    time_taken > 60.0 ? 0 : attempt.size * (1.0 - (time_taken / 60.0))
  end

  def run_game(attempt, grid, time_taken)
    # Check if the word is composed of letters from the grid
    if included?(attempt.upcase, grid)
      # Check if the word exists in English via API
      if english_word?(attempt)
        # Compute score based on word length and time taken
        score = compute_score(attempt, time_taken)
        # Return a hash with score, success message, and time
        { score: score, message: "well done", time: time_taken }
      else
        # Word is not valid English
        { score: 0, message: "not an english word", time: time_taken }
      end
    else
      # Word uses letters not in the grid
      { score: 0, message: "not in the grid", time: time_taken }
    end
  end

  def english_word?(word)
    # Construct the API URL to check if the word exists
    # Open the URL and read the JSON response
    # Parse the JSON into a Ruby hash
    # Return true if the word was found
    # If anything fails (network error, word not found), return false
    url = "https://dictionary.lewagon.com/#{word}"
    json = URI.open(url).read
    result = JSON.parse(json)
    result["found"]
  rescue
    false
  end
end
