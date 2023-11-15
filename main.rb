#!/usr/bin/env ruby

require './monte_carlo.rb'

puts "Enter number of simulations"
simulations = gets.chomp.to_i
simulations = 1 if simulations <= 0
simulations = 10000 if simulations > 10000

mc = MonteCarlo.new(simulations)
mc.run_simulations
mc.calculate_odds

puts "Average selections: #{mc.averages}"
puts "Odds: #{mc.odds}"
