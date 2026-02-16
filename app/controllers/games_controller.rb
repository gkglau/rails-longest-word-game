class GamesController < ApplicationController
  require "open-uri"
  require "json"
  def new
    # create a new @letters instance variable storing
    # these random letters from the alphabet.
    # Then display it in the view.
    @letters =  Array.new(10) { ("A".."Z").to_a.sample }
    session[:grid] = @letters
    session[:start_time] = Time.now
  end

  def score
    # params[:userAnswer]
    @attempt = params[:userAnswer]
    @grid = session[:grid] || Array.new(10) { ("A".."Z").to_a.sample }
    start_time = session[:start_time] || Time.now
    end_time = Time.now

    # calcule the result
    time_taken = end_time.to_i - start_time.to_i
    @result = run_game(@attempt, @grid, time_taken)
  end

  private

  def included?(guess, grid)
    guess.chars.all? { |letter| guess.count(letter) <= grid.count(letter) }
  end

  def compute_score(attempt, time_taken)
    time_taken > 60.0 ? 0 : (attempt.size * (1.0 - (time_taken / 60.0)))
  end

  def run_game(attempt, grid, time_taken)
    if included?(attempt.upcase, grid)
      if english_word?(attempt)
        score = compute_score(attempt, time_taken)
        { score: score, message: "well done", time: time_taken }
      else
        { score: 0, message: "not an english word", time: time_taken }
      end
    else
      { score: 0, message: "not in the grid", time: time_taken }
    end
  end

  def english_word?(word)
    url = "https://dictionary.lewagon.com/#{word}"
    json = URI.open(url).read
    result = JSON.parse(json)
    result["found"]
  rescue
    false
  end
end
