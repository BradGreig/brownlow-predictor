# Overview

This page contains a detailed summary of an exploration into building models to predict the AFL Brownlow medal. Eventually it is my goal to place all models into their own GitHub repo's for sharing. There is a fair bit of information below providing a lot of context. If you are only interested in the final predictions, feel free to jump straight to the 2024 predictions (or equally the comparisons against 2023).

On this page you can find the following:

- [What is the Brownlow and why predict it?](#Why)
- [Available data](#data)
- [Data Insights](#data-insights)
- [Predictive models](#predictive-models)
- [2024 Predictions](#predictions)

## What is the Brownlow and why predict it?

The AFL [Brownlow](https://en.wikipedia.org/wiki/Brownlow_Medal) medal is awarded to the best and fairest player over the course of the AFL season (players suspended for a match are deemed ineligible). Voting is performed after each game by the three officiating match umpires in a 3-2-1 fashion (3 being the best). At the end of the season the votes are collated and the Brownlow medal (a.k.a Charlie after its namesake) is awarded. 

The voting is completely blind, with results unknown until the night of the medal ceremony (held at the start of the week before the AFL Grand Final). Since the voting is performed by the match umpires, the voting is completely subjective rather than being objectively based on some pre-determined criteria. This makes the Brownlow more difficult to predict, and adds to the mystery and intruige on the night of the ceremony. Equally, this makes it much more difficult to create a predictive model, however, that just adds interest to exploring the performance of predictive models. For this reason, the goal is not to create a perfect predictive model, instead it is just to see how well such models work.

Despite the fact that the voting is subjective, the votes do typically correlate with a players statistical performance as we shall explore further below. Although there are some fun historical outliers of players recieving votes for not a very statistically significant performance. Therein lies the difficulty.

To investigate the ability to construct a predictive model for brownlow voting I'll explore a few different models. Some of these are based on peoples previous attempts, which I'll highlight later.

## Available data

In the modern era of sports statistics, we have a wealth of statistical data at our disposal deeply analysing each match. Of course, while we have Brownlow voting results dating back to its inception in 1924, the accompanying individual player stats will be severly lacking.

However, as mentioned earlier, Brownlow voting is subjective, therefore raw player statistics may not be the best data to be using in any case. In the 2000's, fantasy sports arrived in the AFL with AFL [Dreamteam](https://en.wikipedia.org/wiki/AFL_Dream_Team#:~:text=AFL%20Dream%20Team%20is%20an,League%20(AFL)%20and%20Toyota.) in 2001 and its competitor AFL [Supercoach](https://en.wikipedia.org/wiki/AFL_SuperCoach). What is of relevance here is that these fantasy games award a score to a players performance in each game. This score is calculated on a pre-determined criteria according to the individual players statistics. Therefore, it accurately summarises a total performance rather than needing a bunch of individual stats. Further, it has been [shown](https://justindatascience.com/predicting-brownlow-votes/) that these fantasy scores correlate well with Brownlow performance.

A great source for AFL statistics is the [fitzRoy](https://cran.r-project.org/web/packages/fitzRoy/vignettes/fitzRoy.html) R package. This conveniently provides an API for obtaining all manner of AFL statistics sourced from multiple databases. This obviously will be of great use for this project.

However, I found it only contained AFL fantasy scores dating back to 2010. Which to be fair, is almost certainly more than enough. But, for the fun of it (glutton for punishment), I decided to see if I could find any additional data to create a larger database than previous models. After a little bit of time hacking together some scripts to scrape data off [Footywire](https://www.footywire.com/) (one of the main repositories of statistical information) I was able to obtain additional fantasy data for the 2007 - 2009 seasons. 

In total, I have individual player statistical data (including Brownlow and fantasy scores) spanning 2007 - 2023 to explore. This corresponds to a total of 3023 games. The goal is to create a predictive model for the 2024 season, so we have those 198 games as well. Obviously without the Brownlow information.

## Data Insights

There is a considerable amount of individual player statistical data available, not all of which correlate with a players chances of getting Brownlow votes. Let's take a look into the data and see what interesting insights we can obtain about what statistics may be useful to predict a players chances of receiving Brownlow votes. This will help us decide what information to focus on for predicting our models.

For the purposes of creating predictive models, raw numbers are not going to be overly helpful for most statistics. This is for multiple reasons: (i) game conditions; wet/dry games lead to different distributions of statistics, (ii) game styles; rule changes over the years lead to different team strategies and game style and (iii) it allows us to deal with the shortened matches in 2020 due to Covid-19. There are a few different ways we could choose to do this and we will look into a few of those here. For example, we can normalise each individual statistic according to the match statistics (which emphasises players who got the most disposals/goals etc.). This could either be as a zero to one (one being highest total of that statistic). Alternatively, this could be as a fraction (e.g. 10 per cent of all goals kicked in the game). We could equally just rank all players 1-40 odd, for the most/least of each statistic. All these should work out to behave similarly, but some are more intuitive for obtaining insights.

### Raw player statistics that led to Brownlow votes

To begin with, lets look at what statistics lead to 3-2-1 votes in all our historical games.

![Brownlow vote game statistics](https://github.com/BradGreig/brownlow-predictor/blob/main/data/raw_info.png?raw=true)

Here, for a variety of available statistics, we are looking at the fraction of times a player with a given statistic polls 1 (purple), 2 (blue) or 3 (red) votes compared to the total number of times a player has acheived that equivalent statistic. The black curve is simply the sum of all possible voting outcomes (i.e. any vote achieved). For example, in the first panel (for total disposals), a player who achieves 40 disposals has gotten a Brownlow vote roughly 80 per cent of the time (black curve is at roughly 0.8). More specifically, it is 3 votes 50 per cent of the time, 2 votes 25 per cent of the time and 1 vote about 5 per cent of the time. 

In representing the information in this way, we are able to get a good grasp on which particular statistics are most important for determining who receives Brownlow votes. However, this information does not take into account the rarity of achieving these statistical feats. For example, achieving 50 disposals in a game, or kicking over 10 goals does not happen very often. In fact, both have only happened a handful of times in over 15 years of data shown in these graphs. In a data sense these are referred to as rare events (or outliers), and we want to limit the number of these as they are going to be problematic for our models. This is exactly why normalising the information in some manner is important. For example, ranking by disposals. This ensures the player with the most disposals is always ranked first. More on that later.

In any case, we can draw some useful insights from these graphs. For example;

- **Disposals:** The chance of receiving a Brownlow vote rapidly increases after about 25 disposals.
- **Marks:** Obtaining more marks increases your chance of a brownlow vote, however, at more than 15 in a game (rare) it is still only a 50 per cent chance of a vote. Therefore, the number of marks are not overly relevant to a chance of receiving votes.
- **Kicks and handballs:** Correlate similarly, the more you have the higher the chance of voting. The total of these is your disposals, so this is not too surprising.
- **Goals:** A player kicking 5 goals in a game has a 50 per cent chance of getting a Brownlow vote. This becomes almost 90 per cent if they kick 6. Kicking 8 or more is at least an 80 per cent chance of obtaining 3 votes. Doing so is increasingly rare though.
- **Hitouts:** The primary statistic for a ruckman (typically the tallest player on the ground). They aim to hit the ball to the advantage of their team at all stoppages. Traditionally, the ruckman polls incredibly poorly, and this panel shows why. Until they are achieving 60 (which is extremely rare), the number of hitouts seemingly does not matter for achieving a Brownlow vote. Even at 60 hitouts, its a barely 50 per cent chance of receiving a vote (only 25 per cent chance of getting 3 votes). Therefore, for a ruckman to actually poll well in a game, they will equally have to have an impact on the game through a high number of disposals and/or goals. A tough job!
- **Tackles:** The total number of tackles does not particularly matter. The more helps, but it barely increases the chance of getting votes.
- **Inside 50s:** Tracks fairly similarly to the total of marks. Achieving a large number increases you chances as either you are getting a lot of disposals or contributing to your team scoring.
- **Clearances and contested possessions:** Correlate fairly strongly with voting performance. Here, a player is almost certainly in the eyeline of the umpire increasing the chances of standing out.
- **Contested marks:** Typically the forte of forwards or defenders. But typically there are not too many in a game. A large number is likely going to correlate with a large number of shots at goal if you are a forward. For a defender, you are not going to stand out. Hence, key defenders rarely poll at all. The rarity of games with notable numbers means this statistic does not contribute significantly.
- **Goal assists:** Are getting the ball to a teammate who subsequently kicks a goal. Unless you achieve a high number of these (over 5), it has little bearing on performance.
- **AFL Fantasy and Supercoach:** Unsurprisingly, a high score in these strongly correlates to Brownlow performance. These provide a single score summarising a players match performance based on the earlier statistics. Therefore, these will be important for our predictive model. Interestingly, achieving a Supercoach score of over 200 does not guarantee a vote! In Round 10 2007, Josh Drummond achieved 227 and did not poll a vote. In Round 13 2008, Joel Bowden scored 223 and equally did not poll!

### Ranked match performance by Brownlow votes

As highlighted earlier, the actual raw statistics are less relevant as there is theoretically no upper limit to how many of any one statistic that can be achieved. Therefore, to improve the data quality in preparation for our predictive models, lets now look at some normalised data. Here, we ranked each achieved statistic (1-44). The most disposals achieves 1, second most 2 etc. 

Below, we show the cumulative probabilies of achieving 1, 2 or 3 votes as a function of the ranking of that statistic. The cumulative probability is simply the total probability within a range (i.e. up to a particular ranking in our case), with it can achieve a maximum of one. The advantage of using cumulative probilities is that it allows us to quickly observe how important the ranking is to achieving Brownlow votes. If important, the cumulative probability will rapidly approaches one for only the highest rankings. For those that are less relevant, the cumulative probability approaches one much more slowly, requring us to go further down our list of rankings until we achieve all possible cases of achieving a Brownlow vote.

![Brownlow votes by ranking](https://github.com/BradGreig/brownlow-predictor/blob/main/data/rankedinfo.png?raw=true)

Again, these are extremely useful for understanding the importance of an individual statistic on receiving Brownlow votes. In fact, these are more informative than what we observed previously.

- **Disposals:** 75 per cent of the time, 3 votes are awarded to the player who achieves the top 5 most disposals in a game. It decreases for lower votes, highlighting that 1 or 2 votes are more frequently awarded to players with fewer disposals (i.e. they did something else to stand out to the umpires). The cumulative probability then grows more slowly with decreasing rank highlighting that votes can still be awarded to players who do not achieve a high number of disposals (although it is less common)
- **Marks:** This is almost a straight line, highlighting how little bearing the total number of marks a player has on the ability to achieve Brownlow votes.
- **Kicks and handballs:** Unsurprisingly these reflect the behaviour of total disposals (the sum). Kicks are valued more highly, as indicated by the higher cumulative probability than handballs for a similar rank. This just emphasises that kicks are more important in the game (i.e. move the ball further).
- **Goals:** In viewing it as a cumulative probability, it seems this is not as relevant. However, that has more to do with the fact that it is extremely rare to kick 5 or more goals in a game and it even more rate for more than one player to do it in a game. Arguably, this indicates it could be preferable to use total goals rather than most goals in a game as a feature for our model. More on that later.
- **Hitouts:** The ruckman will appear in the first few ranks as only the player in that position is going to be achieving large numbers of hitouts. The fact the cumulative probability is flat until rank 5, highlights how few votes are awarded to an actual ruckman.
- **Tackles:** Similar to the number of marks, it has very little bearing but it does have a slightly larger separation in the breakdown of 3-2-1 votes.
- **Inside 50s:** Achieving a high number of inside 50s has an impact, however, it is less significant than other statistics. But it could be useful as an extra feature or discriminator.
- **Clearances and contested possessions:** Again, these are important. Being top 5 in these acheives 3 votes over 50 per cent of the time. Not as important as total disposals or the fantasy scores, but still extremely important.
- **Contested marks and goal assists:** Achieving the highest ranking in these statistics does not guarantee a high chance of polling brownlow votes. Again, only exceedingly rare, high totals appear to improve the chances.
- **AFL Fantasy and Supercoach:** The top 5 ranked players in either fantasy score achieve Brownlow votes over 80 per cent of the time. The top 10 is close to 95 per cent. Therefore, both of these will be the most important.

As noted above, for most of our statistics, ranking from highest to lowest appears to provide a strong discriminator. However, for some statistics, where rarity is more important (e.g. total number of goals), a ranking may not suit. Therefore, likely a combination is probably required to achieve the best performance for our predictive models. However, we shall not look into that yet, with a focus on just getting a model working in the first place.

Finally, it is worth pointing out here that the Brownlow is colloquially known as the midfielders medal. That is, it is almost exclusively won by a player in these positions. Midfielders achieve the highest disposals, clearances and contested possessions. And cumulativley, these lead to the highest fantasy scores. We can see clearly that this tracks with what we see in the data.

### Which statistics to focus on for the predictive models

Following on from the insights above, I now outline which statistics I choose to keep for creating the predictive models. Additionally, although it may not be suitable for all statistics (e.g. goals), for now I will choose to normalise each statistic by the maximum achieved number in the game. That is, if 40 was the most disposals and 35 was the second most, these would result in values of 1 and 0.875, respectively. This is similar to the ranking scheme above, although should be slightly better as it more significantly distinguishes rarer events (second value will differ by larger amounts).

- **Disposals:** An obvious choice, given its importance. Note, I do not use the kicks and handballs independently as these are embedded in the total disposals.
- **Goals:** Although by normalising it, I may be diminishing its value. I will explore this later.
- **Tackles:** Not overly important, but it is more important than marks which I have excluded. Might be a nice discrimator.
- **Inside 50s:** Was significant enough to include.
- **Clearances:** Found to be relatively significant.
- **Contested possesions:** Also found to be relatively significant.
- **Goal assists:** Not overly significant, but enough to discrimate between players.
- **AFL Dreamteam:** Extremely significant.
- **AFL Supercoach:** Extremely significant.
- **Winning team:** A binary choice, with one indicating a player from the winning team and zero for a losing team (in a draw, everyone is assigned one). This is to crudely account for the fact that you are considerably more likely to poll Brownlow votes when your team wins the match.

Note, I have only excluded total marks, contested marks and hitouts from the graphs from earlier.

Finally, it is important to note I have included both fantasy scores (Supercoach and Dreamteam). And these equally are dependent on other statistics. In general, one does not want to include too many dependent variables (if any) into the models. However, they are different enough to each bring unique value to the model and contain additional information (e.g. disposal efficiency, number of player mistakes).

At this point it would be worth highlighting that I could (probably should) do an elaborate sensitivity analysis, trialling different combinations of various statistics to be used in our predictive models to see how significant each statistic is to the overall model performance. This way I can determine which statistics are of most importance (or even different normalisations) and reduce the complexity of the models. The importance of each statistic can be explored by calculating quantities such as the Akaike Information Criterion when including/excluding a particular statistic. If it suitably improves the model predictions, it is worth using that particular model feature. I might do this in future, but definitely not yet. 

## Predictive models

Briefly searching the web, I stumbled upon a few existing models to predict the AFL Brownlow: (i) Ordinal Logistic Regression combined with Monte Carlo simulations [Monte ChaRlo](https://chewthestat.com/monte-charlo-using-data-to-predict-the-brownlow-medal/) (ii) [automated machine learning](https://github.com/betfair-datascientists/predictive-models/blob/master/brownlow/Betfair%20Data%20Scientists'%20Brownlow%20Model.ipynb) (iii) [simple ranking based approach](https://justindatascience.com/predicting-brownlow-votes/) and (iv) a [random forest approach](https://towardsdatascience.com/brownlow-medal-predictor-36586d535226)

Each slightly differs in their predictive model methodology or the volume of data (and features used) and were extremely helpful resources when constructing my own models or for providing me with ideas.

For now, my likely overly ambitious goal is to create several different predictive models based on a variety of these and other different methodologies.

### Random Forest Classification

The logical go-to first attempt for a Brownlow predictor. A random forest is simply a collection (ensemble) of decision trees. These decision trees, are a supervised learning algorithm for classification tasks which is exactly what we are dealing with (3-2-1-0 voting given a players statistics). Each of these decision tress is simply trained on our input historical data to construct a series of logical (true/false) decisions to convert our input statistics to an output vote. For example, did a player kick 10 goals in a game? Yes, then that's likely to be 3 votes. For a more run of the mill game, it would need to go through all the players statistics to see if they did anything significant warranting a Brownlow vote.

Implementing a random forest classifier is fairly straightforward, with numerous available packages. For me, I implemented a random forest using the scikit-learn package in Python. To train, we simply pass in our normalised statistical match data and the corresponding votes awarded for each of these players. It then learns the criteria needed to distinguish between our Brownlow voting.

In preparation for the 2024 Brownlow, we want to train and verify our methodology against known results. Therefore, to build the random classifier model we will use the 2007 - 2022 data to predict the 2023 Brownlow (won by Lachie Neale from Brisbane). For our model, we will use those statistical quantities that we determined earlier to be important for being awarded Brownlow votes. 

Importantly, when applying our random forest, we cannot directly enforce that 6 Brownlow votes are awarded in each match. Instead, we pass an individual players normalised match statistics to our trained random forest and we obtain a probability for each of the possible outcomes (classes; that is 0, 1, 2 or 3 votes). Since a random forest is a collection of decision trees, this probability is simply the number of decision trees that predicted a particular vote relative to the total number of decision trees.

We then need to use these probabilities to determine our actual 3-2-1 voting. To do so, we calculate an expected number of votes. This is calculated as;

$$
P({\rm expected}) = P({\rm 1\,vote}) + 2*P({\rm 2\,votes}) + 3*P({\rm 3\,votes}).
$$

Which is simply the sum of the probability of each outcome multiplied by its corresponding vote amount and we compute this for each player. Importantly, the sum of this quantity for a match can be more or less than the maximum 6 votes that can be awarded within any given match. Therefore, we have to renormalise the expected probabilities to ensure they correspond to 6.

With this information, we can do one of two things. We can take the list of expected votes, and simply award 3-2-1 to the players with the highest expected votes within a single game. This enables us to preserve the 3-2-1 voting. Repeating over the full season, we obtain a single observation of a voting count reflective of the actual Brownlow. Alternatively, we can just sum the expected votes for each player over the course of the season. The player with the highest expected votes at the end of the season is then the predicted winner. However, the total votes are fractional, and the total and difference is less intuitive (but the season total still adds up to the correct number of votes due to our earlier normalisation step). The former is likely better for predicting the actual vote count, however, the latter includes more variability, better handling the more apparent randomness of awarding 1 and 2 votes. Therefore, it is likely stronger at predicting the actual winner and other place getters. Throughout we will always provide both for the same predictive model.

For our first random forest model, we train a random forest containing a 100 decision trees.

For the second model, we instead train a larger number of random forests (100 with 100 decision trees each). Primarily the reason for doing so is to explore the statistics of an individal players expected votes. By constructing 100 random forests, I can obtain a distribution of 100 expected votes per player per match. This enables me to estimate an uncertainty (i.e. how accurate I think the model has estimated the expected votes). For example, in our first model, we obtain a single expected vote value based on one model (set of initial conditions). Now, by having a distribution, we can quantify if this is narrow or broadly distributed. If broadly distributed, this means there is high uncertainty in our particular players statistics. If narrowly distributed, we have high certainty we are correctly estimating their expected votes. Importantly, it should not really change the overall predictions, however, it allows an additional uncertainty to be assigned to our end of seasons predictions. That is, rather than simply providing a vote tally, we can equally provide an estimate for how likely the player is at actually winning. Players with a low uncertainty, we will be fairly confident about their final performance. Players with a high uncertainty could poll very well, or equally very poorly. This could be useful for explaining a better/worse than expected performance of an individual player.

Finally, one last important point to make is that when training these predictive models, we do not use all of the available player statistics. The reasoning for this is that in a single match, only 3 players can be awarded votes. The remaining 41 players are awarded zero votes. For this classification task, this leads to a large amount of noise in the predictive models. Therefore, we limit the number of zero voted players to be included in our training sample to be 12 (4 times the number of players awarded votes). These 12 players are selected at random.

### Ordinal Logistic Regression

Inspired entirely by the Monte ChaRlo approach, this is a mathematical technique for dealing with ordered voting.

Still a work in progress on this one. Stay tuned.

### Simulation Based Inference

Absolutely no idea if this will work, however, this is a machine learning technique I am familiar with from my days as an astrophysicist. This technique will allow us to turn the voting prediction into a Bayesian inference problem. This is almost certainly way over the top for this problem, however, I just wanted to give it a shot to see how it would work. Below you can find more technical details on this approach, however, equally feel free to skip this entirely!

Bayesian inference is predicting the probability of an outcome based on our model. In our case, the probability of receiving Brownlow votes based on the individual player statistics. This is referred to as a posterior (effectively our random forest classifier has been returning the mean of this posterior). To evaluate this, we need to calculate it using Bayes' theorem;

$$
P(\theta | x) = \frac{P(x | \theta)P(\theta)}{P(x)}
$$

Here, $$ P(\theta | x) $$ is the posterior, which is the probability distribution of obtaining our Brownlow vote, $$ \theta $$, given our observation, $$ x $$ (the set of players individual match statistics). To obtain this posterior, we multiply the likelihood function, $$ P(\theta | x) $$, by our prior, $$ P(\theta) $$, divided by our evidence, $$ P(x) $$. The most important term here is the likelihood, which describes the probability of obtaining our observation $$ x $$ (i.e. player statisics) given our Brownlow vote (e.g. the probability that those statistics occur when achieving 3 votes). The prior simply quantifies our knowledge about Brownlow voting and the model evidence is probability of our observation $$ x $$ being represented by our model. 

Calculating both the likelihood and evidence can be extremely computationally expensive. Thankfully, there are numerous clever mathematical techniques to estimate these (or avoid them entirely). Importantly, the actual details of these methods are well beyond the point of this exploration.

The method I will employ here is Simulation Based Inference (SBI). More specifically, marginal neural ratio estimation (MNRE) to obtain the posterior (the probability that a particular player obtains a vote given their performance). Basically, we use machine learning to train a model to estimate the likelihood to evidence ratio given all the available historical statistical data (our training data). Then, once we have this, we simply pass in a players statistics, and we return the posterior, which is a posterior distribution describing how likely it is at obtaining zero, 1, 2 or 3 Brownlow votes. This posterior will be a continuous distribution (not discrete like our 3-2-1 voting), however, we can easily convert the associated probabilities into such a voting scheme.

To train the SBI model I use the exact same training set as that used for the random classifer (again, limiting the total number of players in each game who received zero votes).

Once the model is complete, we are able to obtain our posterior for the Brownlow voting for each individual player in a match based on their match statistics. This allows us to know how likely a certain vote is expected to occur.

## Validation against 2023

As mentioned earlier, prior to using our models to predict the Brownlow, we must validate our models against known results. Previously, we constructed our training sets based on the 2007 - 2022 data, with the intention of validating against the 2023 results.

In preparation for this validation step, we provide the 2023 Brownlow top 10.

| Ranking | Player Name | Team | Total votes |
| -------- | ------- | -------- | ------- |
| 1 | Lachie Neale | Brisbane | 31 |
| 2 | Marcus Bontempelli | Bulldogs | 29 |
| 3 | Nick Daicos | Collingwood | 28 |
| 4 | Zak Butters | Port Adelaide | 27 |
| 5 | Errol Gulden | Sydney | 27 |
| 6 | Christian Petracca | Melbourne | 26 |
| 7 | Jack Viney | Melbourne | 24 |
| 8 | Caleb Serong | Fremantle | 24 |
| 9 | Noah Anderson | Gold Coast | 22 |
| 10 | Patrick Cripps | Carlton | 22 |

Lachie Neale was the eventual winner. However, what is important to know is that this was somewhat of a surprise. Most people (and predictive models) did not anticipate him winning. Therefore, in our validation, it is important to remember this as predicting the winner might be difficult.

### Random Forest Classification.

#### Model 1

Below, we provide our predictions for the 2023 Brownlow medal based on our first random forest model. That is, one single realisation of a random forest. Remember, for each model, we provide a predicted total preserving the 3-2-1 voting and also an expected vote total, providing a fractional total of the 6 votes that are possible in a single game.

|  | Prediction (Total) |  |  |  |   | Prediction (Expected Votes) |  |  |  | 
| -------- | ------- | -------- | ------- | -------- |
| Ranking | Player Name | Team | Total votes | Actual votes (position) | | Player Name | Team | Total votes | Actual votes (position)
| 1 | Nick Daicos | Collingwood | 32 | 28 (3rd) | | Caleb Serong | Fremantle | 23.74 | 28 (=7th) |
| 2 | Tim Taranto | Richmond | 30 | 19 (16th) | | Nick Daicos | Collingwood | 23.60 | 32 (3rd) |
| 3 | Lachie Neale | Brisbane | 29 | 31 (1st) | | Tim Taranto | Richmond | 21.04 | 19 (16th) |
| 4 | Caleb Serong | Fremantle | 28 | 24 (=7th) | | Errol Gulden | Sydney | 20.94 | 27 (5th) |
| 5 | Jordan Dawson | Adelaide | 26 | 20 (=13th) | | Christian Petracca | Melbourne | 20.85 | 26 (6th) |
| 6 | Christian Petracca | Melbourne | 23 | 26 (6th) | | Marcus Bontempelli | Bulldogs | 20.02 | 29 (2nd) |
| 7 | Marcus Bontempelli | Bulldogs | 23 | 29 (2nd) | | Rory Laird | Adelaide | 19.83 | (=13th) |
| 8 | Tom Green | GWS | 22 | 16 (=22nd) | | Jordan Dawson | Adelaide | 19.59 |  20 (=13th) |
| 9 | Errol Gulden | Sydney | 22 | 27 (=4th) | | Zak Butters | Port Adelaide | 18.32 | 27 (=4th) |
| 10 | Zak Butters | Port Adelaide | 21 | 27 (=4th) | | Zach Merrett | Essendon | 17.78 | (=19th) |

Unfortunately, we did not predict the winner. He was predicted to be 3rd when applying 3-2-1 based on the ranked three highest probabilities in the match. However, in our expected votes model did not even have Lachie Neale in the top 10. While he was a surprise winner, this is potentially indicative that more work is required.

In total, our model based on 3-2-1 voting predicted 7 of the top 10 (but not in the correct order). Our expected votes model predicted 6 of the top 10 (not correct order), with the winner completely absent. Overall, this actually is not too bad, indicating that our models are performing reasonably for a first attempt. Certaintly there is plenty of room for improvement.

To assess our model performance a bit more quantitatively, we can look at the overall accuracy of the model. Essentially, how often did it predict the correct 3-2-1-0 voting per match over the course of the season. For our first model, we obtain an accuracy of 82 per cent. Which does not seem too bad. However, this is going to be significantly dominated by the number of zero vote games (if the model predicted zero votes for every single player it would have an accuracy of 80 per cent!). It is then more instructive to look at how well it predicted the players obtaining the correct 3-2-1 votes. For this, we determine an accuracy of 63, 39 and 32 per cent for 3-2-1 votes, respectively. It is not surprising to be considerably lower, given the subject nature of voting. Further, awarding 3 votes is considerably easier than awarding 2 or 1 votes. A much broader range of players typically perform well enough to be awarded at least one vote, therefore it is somewhat random who actually receives that vote. Further, estimating the accuracy in this way does not take into account whether or not we got the correct ordering of the voting. For example, giving a player 2 instead of the actual 1 or 3 they received. However, it provides a useful illustrative example of how the model is performing.

Importantly, this accuracy breakdown is only valid to our model that applies the 3-2-1 voting based on the three highest probabilities in the match. Using the expected votes total does not actually care about who actually received votes as all players are awarded some fractional total of what is available. Therefore, this approach is considerably better at handling the increased uncertainty around who actually could receive votes and in what order they could possibly have received them.

A more accurate quantitative measure to determine performance would be to consider something like the mean square error (MSE);

$$
{\rm MSE} = \frac{1}{N}\Sigma^{n}_{i=1}(V_{i} - V^{^}_{i})^{2},
$$

which is simply the sum of the square of the difference between the true vote amount ($$ V_{i} $$) and the predicted vote amount ($$ V^{^}_{i} $$). The goal is to have this quantity get as close to zero as possible (all votes predicted correctly).

- At this point, I still need to calculate this quantity! However, for both approaches it still has its problems, which is why I have not prioritised it yet. While it can be applied to both approaches (3-2-1 or expected votes) which is advantageous, it still can be biased by the number of zeros when considering 3-2-1 voting. For expected voting, since it can be fractional, the differences can be larger.

#### Model 2

Below, we provide the total and expected votes predictions for our second random forest model (results determined over an ensemble of 100 random forests).

|  | Prediction (Total) |  |  |  |  | Predictions (Expected Votes) |  | 
| -------- | ------- | -------- | ------- | -------- | ------- | ------- | ------- |
| Ranking | Player Name | Team | Total votes | Actual votes (position) | | Player Name | Team | Expected votes | Actual votes (position) |
| 1 | Tim Taranto | Richmond | 32 | 19 (16th) | | Caleb Serong | Fremantle | 20.85 | 24 (=7th) |
| 2 | Nick Daicos | Collingwood | 32 | 28 (3rd) | | Christian Petracca | Melbourne | 20.51 | 26 (6th) |
| 3 | Lachie Neale | Brisbane | 29 | 31 (1st) | | Nick Daicos | Collingwood | 20.11 | 28 (3rd) |
| 4 | Caleb Serong | Fremantle | 29 | 24 (=7th) | | Marcus Bontempelli | Bulldogs | 19.98 | 29 (2nd) |
| 5 | Jordan Dawson | Adelaide | 25 | 20 (=13th) |  | Tim Taranto | Richmond | 18.97 | 19 (16th) |
| 6 | Rory Laird | Adelaide | 24 | 20 (=13th) | | Rory Laird | Adelaide | 18.33 | 20 (=13th) |
| 7 | Marcus Bontempelli | Bulldogs | 24 | 29 (2nd) | | Errol Gulden | Sydney | 17.60 | 27 (=4th) |
| 8 | Clayton Oliver | Melbourne | 23 | 6 (=59th) | Zak Butters | Port Adelaide | 17.32 | 27 (=4th) | 
| 9 | Tom Green | GWS | 23 | 16 (=22nd) | | Jordan Dawson | Adelaide | 17.06 | 20 (=13th) |
| 10 | Christian Petracca | Melbourne | 23 | 26 (6th) |  | Lachie Neale | Brisbane | 16.56 | 31 (1st) |

At first glance, these predictions look fairly similar to that of the first random forest model. Again, we do not predict the winner of Lachie Neale. Interestingly, awarding only 3-2-1 voting to the three highest probabilities of receiving votes (after averaging over the 100 random forest) has performed the worst of the lot. It only predicts 6 of the top 10, and weirdly has Clayton Oliver in the top 10 despite an actual equal 59th finish. Something probably has gone awry there requiring further investigation. 

With respect to expected votes, this performs equally well as the earlier models, recovering 7 of the top 10 (out of order of course). Unfortunately, at this point I have not found the time to add in the uncertainties (errors) associated with the voting which was the point of this model. However, I added the predictions to be able to use it for the 2024 results.

For this model, I recovered an overall accuracy of 82 per cent, similar to that of model 1 (again, this is dominated by the zero vote predictions). Breaking it down further, I recovered an accuracy of 65, 40 and 29 per cent for correctly predicting the 3, 2 and 1 vote winners. This is slightly higher than the 63, 39 and 32 per cent of model 1. But this should not be too surprising as we are using a much larger number of decision trees in our random forest.

- I still need to compute the mean square error (MSE) for this model as well.

### Ordinal Logistic Regression

Have not found the time to start working on this yet, but will soon.

### Simulation Based Inference

Below is a first attempt at getting SBI to predict the 2023 Brownlow medal. At this point, I am not 100 per cent confident it is working perfectly. I have not had the time to investigate it to the level of rigour it needs. There are likely many improvements that can be made to improve its overall performance. For example, the resultant posteriors are rather broad, much broader than expected. This could be caused by a larger number of reasons: (i) insufficient training data (ii) too many unimportant parameters and/or (iii) sub-optimal machine learning architecture. These will need a more detailed exploration behind the scenes!

Nevertheless, putting that all aside, I will still provide its current predictions. However, note that things are likely change (hopefully improve!).

|  | Predictions (Total) |  |  |   |
| -------- | ------- | -------- | ------- |
| Ranking | Player Name | Team | Total votes |
| 1 | Christian Petracca | Melbourne | 35 | 26 (6th) |
| 2 | Caleb Serong | Fremantle | 34 | 24 (=7th) |
| 3 | Nick Daicos | Collingwood | 28 | 28 (3rd) |
| 4 | Tim Taranto | Richmond | 27 | 19 (16th) |
| 5 | Lachie Neale | Brisbane | 27 | 31 (1st) |
| 6 | Marcus Bontempelli | Bulldogs | 27 | 29 (2nd) |
| 7 | Jordan Dawson | Adelaide | 26 | 20 (=13th) |
| 8 | Zak Butters | Port Adelaide | 25 | 27 (=4th) |
| 9 | Rory Laird | Adelaidet | 24 | 20 (=13th) |
| 10 | Errol Gulden | Sydney | 24 | 27 (=4th) |

Note, for now I have only been able to provide a tally by awarding 3-2-1 votes to the three players with the highest probabilities of obtaining votes (highest means from the posterior). Due to the unexpectedly broad posteriors, computing an expected vote has not been very illuminating. Therefore, I refrain from providing that until I can find the time to work on fixing up this model.

Despite the potential issues, this first attempt at an SBI approach has provided reasonable looking predictions. Again, while not obtaining the correct order, it still correctly identified 7 of the top 10, which is comparable to our previous attempts using a random forest. Therefore, it seems to be ok! Although, that is not overly rigorous.

- As this method is still a work in progress, I do not yet have an estimate of its accuracy. This will be added once I am confident I have make progress in the model performance.


### Possible improvements to the models

For now, the training data I have selected is a set of player statistics that appeared important for determing the chance of receiving a Brownlow vote. Further, this data has been normalised by the total number of a given statistic on a match by match basis. 

However, as highlighted earlier, this normalisation scheme may not be optimal for all statistics (e.g. goals). Additionally, not all of the chosen statistics may be actually be helping the model predictions. Therefore, there is plenty of room available to potentially improve these predictive models (they were only a first attempt). When I find the time, I will investigate improving the normalisation scheme and more rigorously exploring which statistics are most important.

Additionally, I have only implemented a simple binary variable to denote whether a player was on a winning or loosing team. The idea here was to try and avoid too many votes being awarded to players with excellent individual statistics. While it is not impossible to receive votes on a losing team, it is considerably less likely. However, the problem with this simple binary variable is that it equally disadvantages a player irrespective if their team lost by 1 point or 100 points. However, a player in a 1 point loss is considerably more likely to recieve votes than in a 100 point loss (unless you are Gary Ablett Jr.).

For example, below I provide the cumulative probability of receiving Brownlow votes as a function of the winning margin.

![Brownlow votes by winning margin](https://github.com/BradGreig/brownlow-predictor/blob/main/data/margininfo.png?raw=true)

While 3 votes have only been awarded to a player on a loosing team 10 per cent of the time, this jumps to 25 and 30 per cent for receiving 2 and 1 votes respectively. This potentially highlights that by only including a binary variable I might be unfairly restricting the potential of players receiving votes in a loosing team. Therefore, there is potentially room for improvement here.

One of the biggest issue with predicting the Brownlow medal is the subjective nature of the voting rendering the raw player statistics less effective. However, during the season we have other more subjective measures of a players performance. For example, after each game each of the two opposition coaches award 5-4-3-2-1 votes (for a maximum match total of 10). While they almost certainly will have a different opinion than the officiating umpires, this data should improve the predictive nature of our models. Media outlets can also have their own internal award system, awarded by journalists or other members. Therefore, there is potentially a wealth of additional subjective data available to add to our predictive models. I will investigate this in the future.

## 2024 Predictions

In preparation for the upcoming 2024 Brownlow medal, below I provde the predictions for the various models I have considered (or gotten working) thus far.

### Random Forest Classification

First up, our first random forest model.

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

Depending on if you prefer the 3-2-1 scheme or the expected votes, we have a couple of likely winners. Under the expected votes scheme it is clear it is expected to be close between Lachie Neale and Nick Daicos. 3-2-1 voting has Nick Daicos as a runaway winner.

Below, I prove the predictions for our second random forest model (i.e. averaging over 100 random forests). Unfortunately, by the time of the award I had not found the time to get the uncertainties working which should better demonstrate how each player might perform (e.g. high change of a broad range of votes).

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

Unsurprisingly these are fairly similar to our other model. However, I have a higher degree of trust in these owing to the larger number of random forests averaged over (less randomness). This randomness only really impacts awarding the 3-2-1 based on ranked probabilities, with more differences observed on the left hand side of the table. Under the expected votes scheme, the results are very similar, however, we have Nick Daicos being a clear winner (randomness had previously made it appear closer).

Most of these names will be familiar, based on our validation against 2023. A couple of notable exceptions are Adam Treloar, Rowan Marshall and Harry Sheezel. It will be interesting to see how they perform on the night. Unfortuntely, Rowan Marshall is a ruckman, so presumably he will not poll as well!

### Simulation Based Inference

Below you can find our 2024 predictions for the SBI approach. However, huge caution here as this approach still needs a lot of work to fine tune and make sense of (as outlined earlier). However, give that the 2023 predictions seemed reasonable, I've decided to add the 2024 predictions too. I will continue to work away on this model when I find the time.

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

For the most part, this top 10 is fairly similar to those provided by our random forest approaches above. The top 3-4 remain the same, however, there are few changes in the bottom half of the table. Tom Green, Zak Butters and Isaac Heeney in place of Adam Treloar, Rowan Marshall and Harry Sheezel. SBI at least removed the ruckman!

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

Well, the two different approaches did not predict the winner, with Patrick Cripps winning with a record smashing 45! However, they did predict it to be a high count, and predicted Nick Daicos' tally almost perfectly. Interestingly, for all of my models Cripps barely scraped into the top 5 with the models underpredicting his tally by a significant 10 - 20 votes. 

So what went wrong? Well, most likely nothing actually! It seems the quirky, subjective nature of the Brownlow voting played a significant impact. I found an interesting analysis [here](https://www.foxsports.com.au/afl/brownlow-medal/weird-votes-that-let-cripps-smash-record-did-umps-pick-the-wrong-daicos-brownlow-talking-pts/news-story/de783aa761c2af1cc9e9b678c2f7b3b5?gaa_at=la&gaa_n=AWsEHT5-0cFMHnnroJrumDpxreZNUDY5DAUUxsl6ZbITxDo_Kn07laa9nubbGWF3Hu0%3D&gaa_ts=66f20026&utm_source=newsshowcase&utm_medium=discover&utm_campaign=CCwQlY-RlaeSpORTGP7-h4nqsYK5uQEqQwgwEJmd3dDEjtzDIhjPoZ6E9dOr5KABKioIACIQ34S7JIkL8vNsZnoS3qv1FSoUCAoiEN-EuySJC_LzbGZ6Et6r9RU&utm_content=related&gaa_sig=XrTO3sTkjE9JEh-BitgSf0XRn_62n-K1alPmNbm617STHLXIe9kgdlWwnarIF9nObdwZT2Og-EwX2tUwtwInFw%3D%3D). In short, Cripps polled votes (or more votes than expected) in a bunch of games (8 extra votes according to the [Wheelo](https://www.wheeloratings.com/afl_brownlow_live.html) model). While this is not anything new, typically this is balanced out by a player receiving fewer votes than expected in a similar number of games. However, for Cripps, this did not happen. Hence the astronomical number of votes. Poor Nick Daicos...

Unlike the validation of our models for the 2023 season, where we typically correctly identified 7 of the top 10 (although never the correct order), this time around we only successfully identified 4-6 of the top 10. However, after analysing some of the main Brownlow predictors out there; [AFL](https://www.afl.com.au/brownlow-medal/predictor), [Champion Data](https://www.foxsports.com.au/afl/brownlow-medal/brownlow-medal-2024-analysis-and-predictions-stats-preview-who-brownlow-predicting-models-are-tipping-to-win-champion-data-prediction/news-story/088cbaf44510dfa4f4fbf2783e7e77e4), [ESPN](https://www.espn.com.au/afl/story/_/page/POINTSBET20242/afl-2024-ultimate-brownlow-medal-predictor-tracker-leaderboard-odds-every-vote), [Betfair](https://www.betfair.com.au/hub/sports/afl/brownlow-medal-predictor/), [Stats Insider](https://www.statsinsider.com.au/sport-hub/afl/brownlow) and [Wheelo](https://www.wheeloratings.com/afl_brownlow.html), my results were pretty consistent with these other approaches. Therefore, it seems it was a bit of a peculiar year. Case in point, both Marcus Bontempelli and Lachie Neale (last years winner) did not even make the top 10 this year, despite all predictors (including my own) having them both polling very highly. 
Interestingly, my models predicted a very strong performance from Adam Treloar, while no other model did! The fun of playing with data. Equally, my models predicted strong performances from Caleb Serong and Zak Butters who both duly delivered. It also predicted a strong performance from Rowan Marshall, however, given he is a ruckman, its not surprising he did not poll overly well (seemingly a traditional bias against ruckman).

All in all, I would have to say I am quite happy with the performance of these predictive models. Especially given it as a basic first attempt. The next steps are to make some tweaks based on our earlier observations etc., to see if we can improve the overall performance. At least I have an entire year to play around with it. I just need to find the time to make the modifications.

## Contact Information

For any questions please contact [Brad Greig](mailto:brad.s.greig@gmail.com).