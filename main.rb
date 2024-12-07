#!/usr/bin/env ruby

require './monte_carlo.rb'

puts "Enter number of simulations"
simulations = gets.chomp.to_i
simulations = 1 if simulations <= 0
simulations = 10000 if simulations > 10000

start = Time.now.to_i
mc = MonteCarlo.new(simulations)
mc.run_simulations
mc.calculate_odds
finish = Time.now.to_i

puts "Seconds taken: #{finish - start}"

puts "\nAverage selections"
pp mc.averages

puts "\nWomen minimums"
pp mc.women_minimums

puts "\nSelected totals"
pp mc.print_selected_entrants

puts "\nOdds"
pp mc.odds
