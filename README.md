# Monte Carlo simulation for the Hardrock 100

See my [Western States simulation
here](https://github.com/bdlangton/monte-carlo-for-western-states).

Run simulations to calculate your odds of getting into the lottery. This is the
same method used by Hardrock
[themselves](https://www.hardrock100.com/files/entrants/HR100-2023-Lottery-Odds.pdf)
but with this you can run the odds before Hardrock officially publishes the
results.

Note that there could be differences between these results and what Hardrock
publishes. It depends on how many simulation runs you do, but also it depends on
what picks the RD uses and what pools those end up coming from, and whether the
preliminary ticket numbers end up changing.

This does not factor in your odds of getting onto the waitlist, just your odds
of getting selected into the original list of starters.

## Running simulations

You can run simulations by invoking `main.rb` and it'll prompt you for how many
simulations to run. Then it will output the average number of people selected
per category as well as the odds for each category.

```
ruby main.rb
```

You could also start up `irb` and run it that way:

```
load 'monte_carlo.rb'
mc = MonteCarlo.new(<num-of-simulations>)
mc.run_simulations
mc.calculate_odds
```

## Entrants

Entrant counts are hardcoded in `monte_carlo.rb` so make sure those are updated
before running simulations. Previous year values are on [tagged
commits](https://github.com/bdlangton/monte-carlo-for-hardrock/tags).
