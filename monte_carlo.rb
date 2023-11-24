class MonteCarlo
  attr_reader :entrants
  attr_reader :selected_entrants
  attr_reader :averages
  attr_reader :odds

  def initialize(simulations = 1000)
    @simulations = simulations
    @total_picks = 140

    @entrants = {
      "men finished 2" => 37,
      "men finished 3" => 46,
      "men finished 4" => 40,
      "men finished 5" => 25,
      "men finished 6" => 20,
      "men finished 7" => 16,
      "men finished 8" => 7,
      "men finished 9" => 6,
      "men finished 10" => 6,
      "men finished 11" => 3,
      "men finished 12" => 1,
      "men finished 13" => 1,
      "men finished 15" => 3,
      "men finished 19" => 2,
      "men never 1" => 703,
      "men never 2" => 542,
      "men never 4" => 328,
      "men never 8" => 134,
      "men never 16" => 114,
      "men never 32" => 84,
      "men never 64" => 50,
      "men never 128" => 24,
      "men never 256" => 19,
      "men never 512" => 7,
      "men never 2048" => 1,
      "women finished 2" => 12,
      "women finished 3" => 6,
      "women finished 4" => 4,
      "women finished 5" => 5,
      "women finished 6" => 2,
      "women finished 7" => 1,
      "women finished 8" => 1,
      "women finished 20" => 1,
      "women never 1" => 223,
      "women never 2" => 144,
      "women never 4" => 85,
      "women never 8" => 22,
      "women never 16" => 28,
      "women never 32" => 16,
      "women never 64" => 19,
      "women never 128" => 7,
      "women never 256" => 4,
    }

    set_all_tickets
    set_totals_and_minimums

    # Stores sum of all selected entrants for all simulations
    @selected_entrants = new_entrants_list
  end

  def run_simulations
    puts "Running #{@simulations} simulations"

    @simulations.times do
      tickets_left = Marshal.load(Marshal.dump(@all_tickets))
      picks_left = @total_picks
      spots_left = Marshal.load(Marshal.dump(@available_spots))
      women_spots_required = Marshal.load(Marshal.dump(@women_minimums))

      while picks_left > 0 do
        # Select a random ticket and verify it is selectable (accounting for women selected and divisions selected)
        while true do
          chosen = tickets_left[tickets_left.keys.sample]
          if chosen.include?("never") && spots_left["never"] > 0
            if chosen.start_with? "women"
              spots_left["never"] -= 1
              women_spots_required["never"] -= 1
              break
            elsif spots_left["never"] > women_spots_required["never"]
              spots_left["never"] -= 1
              break
            end
          end
          if chosen.include?("finished") && spots_left["finished"] > 0
            if chosen.start_with? "women"
              spots_left["finished"] -= 1
              women_spots_required["finished"] -= 1
              break
            elsif spots_left["finished"] > women_spots_required["finished"]
              spots_left["finished"] -= 1
              break
            end
          end
        end
        @selected_entrants[chosen] += 1

        # Remove appropriate tickets from pool
        removals = 0
        num_to_remove = chosen.split(" ").last.to_i
        tickets_left.each do |ticket_no, ticket_type|
          if ticket_type == chosen
            removals += 1
            tickets_left.delete(ticket_no)
            break if removals >= num_to_remove
          end
        end

        picks_left -= 1
      end
    end
  end

  def calculate_odds
    calculate_averages

    @odds = {}
    @entrants.each do |key, val|
      @odds[key] = (100 * @averages[key] / val).round(2)
    end

    @odds
  end

  # Total number of entrants selected from each division
  # Can be used for verifying that the selection process is working corectly
  def print_selected_entrants
    {
      "men never" => @selected_entrants.select {|x, y| x.start_with? "men never" }.values.sum,
      "women never" => @selected_entrants.select {|x, y| x.start_with? "women never" }.values.sum,
      "men finished" => @selected_entrants.select {|x, y| x.start_with? "men finished" }.values.sum,
      "women finished" => @selected_entrants.select {|x, y| x.start_with? "women finished" }.values.sum,
    }
  end

  private

  def calculate_averages
    @averages = new_entrants_list(true)

    @selected_entrants.each do |key, val|
      @averages[key] = val.to_f / @simulations
    end

    @averages
  end

  def set_all_tickets
    cnt = 0
    @all_tickets = {}

    # Add each individual ticket to the pool
    # The hash value indicates what kind of entrant it is (ex: "men finished 32")
    @entrants.each do |desc, num|
      num_tickets = num * desc.split(" ").last.to_i
      num_tickets.times do
        @all_tickets.merge!({cnt => desc})
        cnt += 1
      end
    end
  end

  def set_totals_and_minimums
    # Use ceil and floor just in case an odd number of entrants is supplied but it should be split evenly
    @available_spots = {
      "finished" => (@total_picks / 2).ceil,
      "never" => (@total_picks / 2).floor,
    }

    @total_finished = @women_finished = 0
    @total_never = @women_never = 0
    @entrants.each do |key, val|
      @total_finished += val if key.include?("finished")
      @women_finished += val if key.start_with?("women finished")
      @total_never += val if key.include?("never")
      @women_never += val if key.start_with?("women never")
    end

    @women_minimums = {
      "finished" => (@available_spots["finished"] * @women_finished / @total_finished).round,
      "never" => (@available_spots["never"] * @women_never / @total_never).round,
    }
  end

  def new_entrants_list(as_double = false)
    entrants_list = {}
    @entrants.each do |key, _|
      entrants_list[key] = as_double ? 0.0 : 0
    end
    entrants_list
  end
end
