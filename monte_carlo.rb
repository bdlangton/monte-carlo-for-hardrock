require 'json'

class MonteCarlo
  attr_reader :entrants
  attr_reader :selected_entrants
  attr_reader :averages
  attr_reader :odds
  attr_reader :women_minimums

  def initialize(simulations = 1000)
    @simulations = simulations
    @total_picks = 144

    @entrants = JSON.parse(File.read("years/2025.json"))

    @divisions = ["never", "finished"]

    set_all_tickets
    set_totals_and_minimums

    # Stores sum of all selected entrants for all simulations
    @selected_entrants = new_entrants_list
  end

  def run_simulations
    count = @entrants.inject(0) {|sum,n| sum + n[1]}
    women_count = @entrants.inject(0) do |sum,n|
      if n[0].include?("women")
        sum + n[1]
      else
        sum
      end
    end

    puts "Running #{@simulations} simulations for #{count} entrants, #{women_count} women"

    @simulations.times do
      tickets_left = Marshal.load(Marshal.dump(@all_tickets))
      picks_left = @total_picks
      spots_left = Marshal.load(Marshal.dump(@available_spots))
      women_spots_required = Marshal.load(Marshal.dump(@women_minimums))
      men_have_been_removed = {
        "never" => false,
        "finished" => false
      }

      while picks_left > 0 do
        # Select a random ticket and verify it is selectable (accounting for women selected and divisions selected)
        while true do
          chosen = tickets_left[tickets_left.keys.sample]
          found = false
          @divisions.each do |division|
            if chosen.include?(division) && spots_left[division] > 0
              # The second condition is assuming the women's minimum is actually a hard stop which seems to make the odds align more with what
              # Hardrock publishes. I thought it was more of "at least this many women must be selected" but maybe it isn't.
              if chosen.start_with?("women") && women_spots_required[division] > 0
                spots_left[division] -= 1
                women_spots_required[division] -= 1
                found = true
                break
              elsif spots_left[division] > women_spots_required[division]
                spots_left[division] -= 1
                found = true
                break
              end
            end
          end
          break if found
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

        # Remove all men from the pool if we're at the point where only women can be selected
        men_have_been_removed.each do |division, val|
          if !val && spots_left[division] <= women_spots_required[division]
            tickets_left = tickets_left.reject do |ticket_no, ticket_type|
              ticket_type.start_with? "men #{division}"
            end
            men_have_been_removed[division] = true
          end
        end
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

    total_finished = women_finished = 0.0
    total_never = women_never = 0.0
    @entrants.each do |key, val|
      total_finished += val if key.include?("finished")
      women_finished += val if key.start_with?("women finished")
      total_never += val if key.include?("never")
      women_never += val if key.start_with?("women never")
    end

    # Total entrants and total womaen entrants
    total = total_finished + total_never
    total_women = women_finished + women_never

    # Percentage of women in each division
    women_finished_percentage = women_finished / total_finished
    women_never_percentage = women_never / total_never

    # Women to select is the percentage of total entrants that are women times the picks to be made
    women_to_select = (@total_picks * (total_women / total).round(2)).round

    # Now we know how many women to select, divide them up amongst finishers and nevers based on those percentages (if there is a higher percentage of
    # women nevers in the total pool of nevers vs the percentage of women finishers in the pool of finishers, then more women nevers will be picked
    # than women finishers. Hardrock has a way of dividing up the women here that I can't figure out but this gets us close at least.
    women_finished_to_select = (women_to_select * women_finished_percentage / (women_finished_percentage + women_never_percentage)).round
    @women_minimums = {
      "finished" => women_finished_to_select,
      "never" => women_to_select - women_finished_to_select,
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
