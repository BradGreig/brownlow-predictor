# Overview

This page contains a summary of an exploration into building models to predict the AFL Brownlow medal. Eventually it is my goal to place all models into their own GitHub repo's for sharing.

On this page you can find the following:

- [What is the Brownlow and why predict it?](#Why)
- [Available data](#data)
- [Data Insights](#data-insights)
- [Predictive models](#predictive-models)
- [2024 Predictions](#predictions)

## What is the Brownlow and why predict it?

The AFL [Brownlow](https://en.wikipedia.org/wiki/Brownlow_Medal) medal is awarded to the best and fairest player over the course of the AFL season. Voting is performed after each game by the three officiating match umpires in a 3-2-1 fashion (3 being the best). At the end of the season the votes are collated and the Brownlow medal (a.k.a Charlie after its namesake) is awarded. 

The voting is completely blind, with results unknown until the night of the medal ceremony (held at the start of the week before the AFL Grand Final). Since the voting is performed by the match umpires, the voting is completely subjective rather than being objectively based on some pre-determined criteria. This makes it more difficult as a predictive model, however, that just adds to the intrigue in exploring the performance of predictive models. For this reason, the goal is not to create a perfect predictive model, instead it is just to see how well such models work.

Despite the fact that the voting is subjective, the votes do typically correlate with a players statistical performance as we shall explore further below. Although there are some fun historical outliers of players recieving votes for not a very statistically significant performance.

To investigate the ability to construct a predictive model for brownlow voting I'll explore a few different models. Some of these are based on peoples previous attempts, which I'll highlight later.

## Available data

In the modern era of sports statistics, we have a wealth of statistical data at our disposal deeply analysing each match. Of course, while we have Brownlow voting results dating back to its inception in 1924, the accompanying individual player stats will be severly lacking.

However, as mentioned earlier, Brownlow voting is subjective, therefore raw player statistics may not be the best data to be using in any case. In the 2000's, fantasy sports arrived in the AFL with AFL [Dreamteam](https://en.wikipedia.org/wiki/AFL_Dream_Team#:~:text=AFL%20Dream%20Team%20is%20an,League%20(AFL)%20and%20Toyota.) in 2001 and its competitor AFL [Supercoach](https://en.wikipedia.org/wiki/AFL_SuperCoach). What is of relevance here is that these fantasy games award a score to a players performance in each game. This score is calculated on a pre-determined criteria according to the individual players statistics. Therefore, it accurately summarises a total performance rather than needing a bunch of individual stats. Further, it has been [shown](https://justindatascience.com/predicting-brownlow-votes/) that these fantasy scores correlate well with Brownlow performance.

A great source for AFL statistics is the [fitzRoy](https://cran.r-project.org/web/packages/fitzRoy/vignettes/fitzRoy.html) R package. This conveniently provides an API for obtaining all manner of AFL statistics sourced from multiple databases. This obviously will be of great use for this project.

However, I found it only contained AFL fantasy scores dating back to 2010. Which to be fair, is almost certainly more than enough. However, for the fun of it, I decided to see if I could find any additional data to create a larger database than previous models. After a little bit of time hacking together some scripts to scrape data off [Footywire](https://www.footywire.com/)(one of the main repositories of statistical information) I was able to obtain additional fantasy data for the 2007 - 2009 seasons. 

In total, I have individual player statistical data (including Brownlow and fantasy scores) spanning 2007 - 2023 to explore. This corresponds to a total of 3023 games. The goal is to create a predictive model for the 2024 season, so we have those 198 games as well. Obviously without the Brownlow information.

## Data Insights

There is a considerable amount of individual player statistical data available, not all of which correlate with a players chances of getting Brownlow votes. Let's take a look into the data and see what interesting insights we can obtain about what statistics may be useful to predict a players chances of receiving Brownlow votes. This will help us decide what information to focus on for predicting our models.

For the purposes of creating predictive models, raw numbers are not going to be overly helpful for most statistics. This is for multiple reasons: (i) game conditions; wet/dry games lead to different distributions of statistics, (ii) game styles; rule changes over the years lead to different team strategies and game style and (iii) allows us to deal with the shortened matches in 2020 due to Covid-19. There are a few different ways we could choose to do this and we will look into a few of those here. For example, we can normalise each individual statistic according to the match statistics (which emphasises players who got the most disposals/goals etc.). This could either be as a zero to one (one being highest total of that statistic). Alternatively, this could be as a fraction (e.g. 10 per cent of all goals kicked in the game). We could equally just rank all players 1-40 odd, for the most/least of each statistic. All these should work out to behave similarly, but some are more intuitive for obtaining insights.

To begin with, lets look at what statistics lead to 3-2-1 votes in all our historical games.

![Brownlow vote game statistics](https://github.com/BradGreig/brownlow-predictor/blob/main/data/raw_info.png?raw=true)

Here, for a variety of available statistics, we are looking at the fraction of times a player with a given statistic polls 1 (purple), 2 (blue) or 3 (red) votes compared to the total number of times a player has acheived that equivalent statistic. The black curve is simply the sum of all possible voting outcomes (i.e. any vote achieved). For example, in the first panel (for total disposals), a player who achieves 40 disposals has gotten a Brownlow vote roughly 80 per cent of the time (black curve is at roughly 0.8). More specifically, it is 3 votes 50 per cent of the time, 2 votes 25 per cent of the time and 1 vote about 5 per cent of the time. 

In representing the information in this way, we are able to get a good grasp on which particular statistics are most important for determining who receives Brownlow votes. However, this information does not take into account the rarity of achieving these statistical feats. For example, achieving 50 disposals in a game, or kicking over 10 goals does not happen very often. In fact, both have only happened a handful of times in over 15 years of data shown in these graphs. In a data sense these are referred to as rare events, and we want to limit the number of these as they are going to be problematic for our models. This is exactly why normalising the information in some manner is important. For example, ranking by disposals. This ensures the player with the most disposals is always ranked first. More on that later.

In any case, we can draw some useful insights from these graphs. For example;
- **Disposals:** The chance of receiving a Brownlow vote rapidly increases after about 25 disposals.
- **Marks:** Obtaining more marks increases your chance of a brownlow vote, however, at more than 15 in a game (rare) it is still only a 50 per cent chance of a vote. Therefore, the number of marks are not overly relevant to a change of receiving votes.
- **Kicks and handballs:** Correlate similarly, the more you have the higher the chance of voting. The total of these is your disposals, so this is not too surprising.
- **Goals:** A player kicking 5 goals in a game has a 50 per cent chance of getting a Brownlow vote. This becomes almost 90 per cent if they kick 6. Kicking 8 or more is at least an 80 per cent chance of obtaining 3 votes. Doing so is increasingly rare though.
- **Hitouts:** The primary statistic for a ruckman (typically the tallest player on the ground). They aim to hit the ball to the advantage of their team at all stoppages. Traditionally, the ruckman polls incredibly poorly, and this panel shows why. Until they are achieving 60 (which is extremely rare), the number of hitouts seemingly does not matter for achieving a Brownlow vote. Even at 60 hitouts, its a barely 50 per cent chance of receiving a vote (only 25 per cent chance of getting 3 votes). Therefore, for a ruckman to actually poll well in a game, they will equally have to have an impact on the game through a high number of disposals and/or goals. A tough job!
- **Tackles:** The total number of tackles does not particularly matter. The more helps, but it barely increases the chance of getting votes.
- **Inside 50s:** Track fairly similarly to the total of marks. Achieving a large number increases you chances as either you are getting a lot of disposals or contributing to your team scoring.
- **Clearances and contested possessions:** Correlate fairly strongly with voting performance. Here, a player is almost certainly in the eyeline of the umpire increasing the chances of standing out.
- **Contested marks:** Typically the forte of forwards or defenders. But typically there are not too many in a game. A large number is likely going to correlate with a large number of shots at goal if you are a forward. For a defender, you are not going to stand out. Hence, key defenders rarely poll at all. The rarity of games with notable numbers means this statistic does not contribute significantly.
- **Goal assists:** Are getting the ball to a teammate who subsequently kicks a goal. Unless you achieve a high number of these (over 5), it has little bearing on performance.
- **AFL Fantasy and Supercoach:** Unsurprisingly, a high score in these strongly correlates to Brownlow performance. These provide a single score summarising a players match performance based on the earlier statistics. Therefore, these will be important for our predictive model. Interestingly, achieving a Supercoach score of over 200 does not guarantee a vote! In Round 10 2007, Josh Drummond achieved 227 and did not poll a vote. In Round 13 2008, Joel Bowden scored 223 and equally did not poll!

![Brownlow votes by ranking](https://github.com/BradGreig/brownlow-predictor/blob/main/data/rankedinfo.png?raw=true)


## Predictive models

Briefly searching the web, I stumbled upon a few existing models to predict the AFL Brownlow: (i) Ordinal Logistic Regression combined with Monte Carlo simulations [Monte ChaRlo](https://chewthestat.com/monte-charlo-using-data-to-predict-the-brownlow-medal/) (ii) [automated machine learning](https://github.com/betfair-datascientists/predictive-models/blob/master/brownlow/Betfair%20Data%20Scientists'%20Brownlow%20Model.ipynb) (iii) [simple ranking based approach](https://justindatascience.com/predicting-brownlow-votes/) and (iv) a [random forest approach](https://towardsdatascience.com/brownlow-medal-predictor-36586d535226)

Each slightly differs in their predictive model methodology or the volume of data (and features used) and were extremely helpful resources when constructing my own models or giving me ideas.

For now, my likely overly ambitious goal is to create several different predictive models based on a variety of different methodologies.

### Random Forest Classification

The logical go-to first attempt for a Brownlow predictor. A random forest is simply a collection (ensemble) of decision trees. These decision trees, are a supervised learning algorithm for classification tasks which is exactly what we are dealing with (3-2-1-0 voting given a players statistics). Each of these decision tress is simply trained on our input historical data to construct a series of logical (true/false) decisions to convert our input statistics to an output vote. For example, did a player kick 10 goals in a game? Yes, then that's likely to be 3 votes. For a more run of the mill game, it would need to go through all the players statistics to see if they did anything significant warranting a Brownlow vote.

Implementing a random forest classifier is fairly straightforward, with numerous available packages. For me, I implemented a random forest using the scikit-learn package in Python. To train, we simply pass in our normalised statistical match data and the corresponding votes awarded for each of these players. It then learns the criteria needed to distinguish between our Brownlow voting.

In preparation for the 2024 Brownlow, we want to train and verify our methodology against known results. Therefore, building of the random classifier model we will use the 2007 - 2022 data to predict the 2023 Brownlow (won by Lachie Neale from Brisbane). For our model, we will use those statistical quantities that we determined earlier to be important for being awarded Brownlow votes. Specifically, we will use the number of disposals (handballs + kicks), goals, tackles, inside 50's, clearances, contested possesions, goal assists, AFL Fantasy, AFL Supercoach scores and whether the player was in a winning/losing team (more likely to receive votes when winning than losing).

Importantly, AFL Fantasy and Supercoach scores include all the other statistical information (except the winning margin). Nevertheless, we include all of them as they help to improve the overall performance of the model predictions. The importance of each can simply be determined by calculating quantities such as the Akaike Information Criterion with/without a particular statistic. If it suitably improves the model predictions, it is worth using that particular model feature. More on this later.

- Need to add more information here 

Finally, we are in a position to evaluate the performance of our model on the 2023 season. In particular, we trialled a few different variations which all performed fairly similarly. Below, you can find the actual top 10 for the 2023 season, along with our predictions.

|  | Actual Results |  |  |  |  | Predictions |  | 
| -------- | ------- | -------- | ------- | -------- | ------- | ------- | ------- |
| Ranking | Player Name | Team | Total votes |  | Player Name | Team | Total votes |
| 1 | Lachie Neale | Brisbane | 31 |  | Nick Daicos | Collingwood | 32 |
| 2 | Marcus Bontempelli | Bulldogs | 29 |  | Tim Taranto | Richmond | 30 |
| 3 | Nick Daicos | Collingwood | 28 |  | Lachie Neale | Brisbane | 29 |
| 4 | Zak Butters | Port Adelaide | 27 |  | Caleb Serong | Fremantle | 28 |
| 5 | Errol Gulden | Sydney | 27 |  | Jordan Dawson | Adelaide | 26 |
| 6 | Christian Petracca | Melbourne | 26 |  | Christian Petracca | Melbourne | 23 |
| 7 | Jack Viney | Melbourne | 24 |  | Marcus Bontempelli | Bulldogs | 29 |
| 8 | Caleb Serong | Fremantle | 24 |  | Tom Green | GWS | 22 | 
| 9 | Noah Anderson | Gold Coast | 22 |  | Errol Gulden | Sydney | 22 |
| 10 | Patrick Cripps | Carlton | 22 |  | Zak Butters | Port Adelaide | 21 |

- Need to provide some observations for these predictions
- Ultimately, it all appears to be working well! We did not get the winner correct, however, there was a little bit of controversy there. Lachie Neale was a bit of an unexpected winner.
- Our top 10 includes 7 of the actual top 10, but in a slightly different order. Not a bad effort.

|  | Actual Results |  |  |  |  | Predictions |  | 
| -------- | ------- | -------- | ------- | -------- | ------- | ------- | ------- |
| Ranking | Player Name | Team | Total votes |  | Player Name | Team | Expected votes |
| 1 | Lachie Neale | Brisbane | 31 |  | Caleb Serong | Fremantle | 23.74 |
| 2 | Marcus Bontempelli | Bulldogs | 29 |  | Nick Daicos | Collingwood | 23.60 |
| 3 | Nick Daicos | Collingwood | 28 |  | Tim Taranto | Richmond | 21.04 |
| 4 | Zak Butters | Port Adelaide | 27 |  | Errol Gulden | Sydney | 20.94 |
| 5 | Errol Gulden | Sydney | 27 |  | Christian Petracca | Melbourne | 20.85 |
| 6 | Christian Petracca | Melbourne | 26 |  | Marcus Bontempelli | Bulldogs | 20.02 |
| 7 | Jack Viney | Melbourne | 24 |  | Rory Laird | Adelaide | 19.83 |
| 8 | Caleb Serong | Fremantle | 24 |  | Jordan Dawson | Adelaide | 19.59 | 
| 9 | Noah Anderson | Gold Coast | 22 |  | Zak Butters | Port Adelaide | 18.32 |
| 10 | Patrick Cripps | Carlton | 22 |  | Zach Merrett | Essendon | 17.78 |

- This is a slightly different approach. More information to come.


|  | Predictions |  |  |  |  | Predictions |  | 
| -------- | ------- | -------- | ------- | -------- | ------- | ------- | ------- |
| Ranking | Player Name | Team | Total votes |  | Player Name | Team | Expected votes |
| 1 | Tim Taranto | Richmond | 32 |  | Caleb Serong | Fremantle | 20.85 |
| 2 | Nick Daicos | Collingwood | 32 |  | Christian Petracca | Melbourne | 20.51 |
| 3 | Lachie Neale | Brisbane | 29 |  | Nick Daicos | Collingwood | 20.11 |
| 4 | Caleb Serong | Fremantle | 29 |  | Marcus Bontempelli | Bulldogs | 19.98 |
| 5 | Jordan Dawson | Adelaide | 25 |  | Tim Taranto | Richmond | 18.97 |
| 6 | Rory Laird | Adelaide | 24 |  | Rory Laird | Adelaide | 18.33 |
| 7 | Marcus Bontempelli | Bulldogs | 24 |  | Errol Gulden | Sydney | 17.60 |
| 8 | Clayton Oliver | Melbourne | 23 |  | Zak Butters | Port Adelaide | 17.32 | 
| 9 | Tom Green | GWS | 23 |  | Jordan Dawson | Adelaide | 17.06 |
| 10 | Christian Petracca | Melbourne | 23 |  | Lachie Neale | Brisbane | 16.56 |

- This is a slightly different version again.
- More descriptions to come


- Some more discussions about possible improvements etc.
- Can improve by modifying the winner/loser binary split. Maybe include a binned margin instead. This allows an increased likelihood that a player on a losing team can score votes if it was a close match. Should lower the advantage for some players on teams who didn't perform as well as above.

### Ordinal Logistic Regression

Inspired entirely by the Monte ChaRlo approach, this is a mathematical technique for dealing with ordered voting.

Still a work in progress on this one. Stay tuned.

### Simulation Based Inference

Absolutely no idea if this will work, however, this is a machine learning technique I am familiar with from my days as an astrophysicist. This technique will allow us to turn the voting prediction into a Bayesian inference problem. More on this below.

Bayesian inference is predicting the probability of an outcome based on our model. In our case, the probability of receiving Brownlow votes based on the individual player statistics. This is referred to as a posterior. To evaluate this, we need to calculate it using Bayes' theorem;

$$
P(x | \theta) = \frac{P(\theta | x)P(\theta)}{P(x)}
$$

Here, we have the product of the likelihood function by our prior divided by our evidence. The likelihood is the probability of the player statistics occuring given our model (e.g. predicting the Brownlow votes). Effectively, a measure of our how well our model is at correlating the players individual statistics to actual Brownlow medal voting. The prior is a measure of our knowledge about the system (e.g. things we know to be true about obtaining Brownlow votes). The final term is the evidence, which estimates the probability of our model representing the real world. 

Calculating both the likelihood and evidence can be extremely computationally expensive. Thankfully, there are numerous clever mathematical techniques to estimate these (or avoid them entirely). Importantly, the actual details of these methods are well beyond the point of this exploration.

The method I'll employ here is Simulation Based Inference. However, more than this we are actually performing marginal neural ratio estimation (MNRE) to obtain the posterior (the probability that a particular player obtains a vote given their performance). Basically, we use machine learning to train a model to estimate the likelihood to evidence ratio given all the available historical statistical data. Then, once we have this, we simply pass in a players statistics, and we return the posterior, which is a posterior distribution describing how likely it is at obtaining zero, 1, 2 or 3 Brownlow votes.

Below is a first attempt at getting SBI to predict the 2023 Brownlow medal. I'm not fully confident this is working properly, with a few additional things needing to be added. However, the predictions seem sensible, so I'll put them here for now. There is a chance that these will change though.

|  | Predictions |  |  |
| -------- | ------- | -------- | ------- |
| Ranking | Player Name | Team | Total votes |
| 1 | Christian Petracca | Melbourne | 35 |
| 2 | Caleb Serong | Fremantle | 34 |
| 3 | Nick Daicos | Collingwood | 28 |
| 4 | Tim Taranto | Richmond | 27 |
| 5 | Lachie Neale | Brisbane | 27 |
| 6 | Marcus Bontempelli | Bulldogs | 27 |
| 7 | Jordan Dawson | Adelaide | 26 |
| 8 | Zak Butters | Port Adelaide | 25 |
| 9 | Rory Laird | Adelaidet | 24 |
| 10 | Errol Gulden | Sydney | 24 |

- Again, this seems reasonable given that our predicted top 10 includes 7 of the final top 10. Although in a slightly different order.

## 2024 Predictions

In preparation for the upcoming 2024 Brownlow medal, below I provde the predictions for the various models I have considered.

### Random Forest Classification

Firstly, our random forest classifiers for the 2024 Season.

|  | Predictions |  |  |  |  | Predictions |  | 
| -------- | ------- | -------- | ------- | -------- | ------- | ------- | ------- |
| Ranking | Player Name | Team | Total votes |  | Player Name | Team | Expected votes |
| 1 | Nick Daicos | Collingwood | 37 |  | Lachie Neale | Brisbane | 26.78 |
| 2 | Caleb Serong | Fremantle | 32 |  | Nick Daicos | Collingwood | 26.37 |
| 3 | Patrick Cripps | Carlton | 31 |  | Caleb Serong | Fremantle | 21.57 |
| 4 | Lachie Neale | Brisbane | 31 |  | Marcus Bontempelli | Bulldogs | 21.46 |
| 5 | Adam Treloar | Bulldogs | 29 |  | Zak Butters | Port Adelaide | 20.56 |
| 6 | Zach Merrett | Essendon | 27 |  | Patrick Cripps | Carlton | 19.76 |
| 7 | Marcus Bontempelli | Bulldogs | 26 |  | Adam Treloar | Bulldogs | 19.65 |
| 8 | Rowan Marshall | St Kilda | 24 |  | Noah Anderson | Gold Coast | 18.94 | 
| 9 | Harry Sheezel | North Melbourne | 23 |  | Harry Sheezel | North Melbourne | 18.57 |
| 10 | Noah Anderson | Gold Coast | 23 |  | Errol Gulden | Sydney | 18.53 |

- Depending on which variant you use, we have a few possible winners.


|  | Predictions |  |  |  |  | Predictions |  | 
| -------- | ------- | -------- | ------- | -------- | ------- | ------- | ------- |
| Ranking | Player Name | Team | Total votes |  | Player Name | Team | Expected votes |
| 1 | Nick Daicos | Collingwood | 37 |  | Nick Daicos | Collingwood | 24.62 |
| 2 | Caleb Serong | Fremantle | 35 |  | Lachie Neale | Brisbane | 23.50 |
| 3 | Lachie Neale | Brisbane | 32 |  | Caleb Serong | Fremantle | 20.33 |
| 4 | Adam Treloar | Bulldogs | 28 |  | Marcus Bontempelli | Bulldogs | 19.97 |
| 5 | Patrick Cripps | Carlton | 26 |  | Zak Butters | Port Adelaide | 19.50 |
| 6 | Rowan Marshall | St Kilda | 26 |  | Patrick Cripps | Carlton | 18.62 |
| 7 | Marcus Bontempelli | Bulldogs | 26 |  | Adam Treloar | Bulldogs | 17.82 |
| 8 | Zach Merrett | Essendon | 25 |  | Noah Anderson | Gold Coast | 17.16 | 
| 9 | Noah Anderson | Gold Coast | 23 |  | Harry Sheezel | North Melbourne | 17.08 |
| 10 | Max Gawn | Melbourne | 23 |  | Errol Gulden | Sydney | 17.06 |

- Fairly similar numbers here as those above. 

- Across all of these results, it's looking like its going to be between Lachie Neale and Nick Daicos as winner of the 2024 Brownlow. 
- A couple of interesting names appearing in the top 10. Adam Treloar and Rohan Marshall being those.


### Simulation Based Inference

Below you can find our 2024 predictions for the SBI approach. However, huge caution as this approach still needs a lot of work to fine tune and make sense. But, our 2023 predictions seemed reasonable, so I'll add the 2024 predictions too.

|  | Predictions |  |  |
| -------- | ------- | -------- | ------- |
| Ranking | Player Name | Team | Total votes |
| 1 | Nick Daicos | Collingwood | 38 |
| 2 | Lachie Neale | Brisbane | 36 |
| 3 | Caleb Serong | Fremantle | 32 |
| 4 | Patrick Cripps | Carlton | 31 |
| 5 | Marcus Bontempelli | Bulldogs | 30 |
| 6 | Noah Anderson | Gold Coast | 28 |
| 7 | Zak Butters | Port Adelaide | 27 |
| 8 | Tom Green | GWS | 26 |
| 9 | Isaac Heeney | Sydney | 25 |
| 10 | Zach Merrett | Essendon | 25 |

- These predictions are quite similar to our random forest ones. So once again, this method appears to be producing sensible results.
- Quite a high count, which is similar to above. Will be interesting to see if this turns out to be the case.

### Performance Against Actual Result

Below is the actual outcome of the 2024 Brownlow:

|  | 2024 Brownlow Medal |  |  |
| -------- | ------- | -------- | ------- |
| Ranking | Player Name | Team | Total votes |
| 1 | Patrick Cripps | Carlton | 45 |
| 2 | Nick Daicos | Collingwood | 38 |
| 3 | Zak Butters | Port Adelaide | 29 |
| 4 | Caleb Serong | Fremantle | 28 |
| 5 | Isaac Heeney* | Sydney | 28 |
| 6 | Tom Green | GWS | 27 |
| 7 | Adam Treloar | Bulldogs | 26 |
| 8 | Errol Gulden | Sydney | 25 |
| 9 | Matt Rowell | Gold Coast | 25 |
| 10 | Jai Newcombe | Hawthorn | 24 |

Well, the two different approaches did not predict the winner, with Patrick Cripps winning with a record smashing 45! However, they did predict it to be a high count, and predicted Nick Daicos' tally almost perfectly. Interestingly, for these models Cripps barely scraped into the top 5 with the models underpredicting his tally by a significant 10 - 20 votes.

So what went wrong? Well, most likely nothing actually! It seems the quirky, subjective nature of the Brownlow voting played a significant impact. I found an interesting analysis [here](https://www.foxsports.com.au/afl/brownlow-medal/weird-votes-that-let-cripps-smash-record-did-umps-pick-the-wrong-daicos-brownlow-talking-pts/news-story/de783aa761c2af1cc9e9b678c2f7b3b5?gaa_at=la&gaa_n=AWsEHT5-0cFMHnnroJrumDpxreZNUDY5DAUUxsl6ZbITxDo_Kn07laa9nubbGWF3Hu0%3D&gaa_ts=66f20026&utm_source=newsshowcase&utm_medium=discover&utm_campaign=CCwQlY-RlaeSpORTGP7-h4nqsYK5uQEqQwgwEJmd3dDEjtzDIhjPoZ6E9dOr5KABKioIACIQ34S7JIkL8vNsZnoS3qv1FSoUCAoiEN-EuySJC_LzbGZ6Et6r9RU&utm_content=related&gaa_sig=XrTO3sTkjE9JEh-BitgSf0XRn_62n-K1alPmNbm617STHLXIe9kgdlWwnarIF9nObdwZT2Og-EwX2tUwtwInFw%3D%3D). In short, Cripps polled votes (or more votes than expected) in a bunch of games (8 extra votes according to the [Wheelo](https://www.wheeloratings.com/afl_brownlow_live.html) model). While this is not anything new, typically this is balanced out by a player receiving fewer votes than expected in a similar number of games. However, for Cripps, this did not happen. Hence the astronomical number of votes. Poor Nick Daicos...

Unlike the validation of our models for the 2023 season, where we typically correctly identified 7 of the top 10 (although rarely the correct order), this time around we only successfully identified 4-6 of the top 10. However, after analysing some of the main Brownlow predictors out there; [AFL](https://www.afl.com.au/brownlow-medal/predictor), [Champion Data](https://www.foxsports.com.au/afl/brownlow-medal/brownlow-medal-2024-analysis-and-predictions-stats-preview-who-brownlow-predicting-models-are-tipping-to-win-champion-data-prediction/news-story/088cbaf44510dfa4f4fbf2783e7e77e4), [ESPN](https://www.espn.com.au/afl/story/_/page/POINTSBET20242/afl-2024-ultimate-brownlow-medal-predictor-tracker-leaderboard-odds-every-vote), [Betfair](https://www.betfair.com.au/hub/sports/afl/brownlow-medal-predictor/), [Stats Insider](https://www.statsinsider.com.au/sport-hub/afl/brownlow) and [Wheelo](https://www.wheeloratings.com/afl_brownlow.html), my results were pretty consistent with these other approaches. Therefore, it seems it was a bit of a peculiar year. Case in point, both Marcus Bontempelli and Lachie Neale (last years winner) did not even make the top 10 this year, despite all predictors (including my own) having them both polling very highly. 
Interestingly, my models predicted a very strong performance from Adam Treloar, while no other model did! The fun of playing with data. Equally, my models predicted strong performances from Caleb Serong and Zak Butters who both duly delivered. It also predicted a strong performance from Rowan Marshall, however, given he is a ruckman, its not surprising he did not poll overly well (seemingly a traditional bias against ruckman).

All in all, I would have to say I am quite happy with the performance of these predictive models. The next steps are to make some tweaks based on our earlier observations etc., to see if we can improve the overall performance. At least I have an entire year to play around with it.


## Contact Information

For any questions please contact [Brad Greig](mailto:brad.s.greig@gmail.com).