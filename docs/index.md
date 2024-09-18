# Overview

This page contains a summary of an exploration into building models to predict the AFL Brownlow medal.

On this page you can find the following:

- [What is the Brownlow and why predict it?](#Why)
- [Available data](#data)
- [Data Insights](#data-insights)
- [Predictive models](#predictive-models)
- [Predictions](#predictions)

## What is the Brownlow and why predict it?

The AFL [Brownlow](https://en.wikipedia.org/wiki/Brownlow_Medal) medal is awarded to the best and fairest player over the course of the AFL season. Voting is performed after each game by the three officiating match umpires in a 3-2-1 fashion (3 being the best). At the end of the season the votes are collated and the Brownlow medal (a.k.a Charlie after its namesake) is awarded. 

The voting is completely blind, with results unknown until the night of the medal ceremony (held at the start of the week before the AFL Grand Final). Since the voting is performed by the match umpires, the voting is completely subjective rather than being objectively based on some pre-determined criteria. This makes it more difficult as a predictive model, however, that just adds to the intrigue in exploring the performance of predictive models. 

Despite the fact that the voting is subjective, the votes do typically correlate with a players statistical performance as we shall explore further below. Although there are some fun historical outliers of players recieving votes for not a very statistically significant performance.

To investigate the ability to construct a predictive model for brownlow voting I'll explore a few different models. Some of these are based on peoples previous attempts, which I'll highlight later.

## Available data

In the modern era of sports statistics, we have a wealth of statistical data at our disposal deeply analysing each match. Of course, while we have Brownlow voting results dating back to its inception in 1924, the accompanying individual player stats will be severly lacking.

However, as mentioned earlier, Brownlow voting is subjective, therefore raw player statistics may not be the best data to be using in any case. In the 2000's, fantasy sports arrived in the AFL with AFL [Dreamteam](https://en.wikipedia.org/wiki/AFL_Dream_Team#:~:text=AFL%20Dream%20Team%20is%20an,League%20(AFL)%20and%20Toyota.) in 2001 and its competitor AFL [Supercoach](https://en.wikipedia.org/wiki/AFL_SuperCoach). What is of relevance here is that these fantasy games award a score to a players performance in each game. This score is calculated on a pre-determined criteria according to the individual players statistics. Therefore, it accurately summarises a total performance rather than needing a bunch of individual stats. Further, it has been [shown](https://justindatascience.com/predicting-brownlow-votes/) that these fantasy scores correlate well with Brownlow performance.

A great source for AFL statistics is the [fitzRoy](https://cran.r-project.org/web/packages/fitzRoy/vignettes/fitzRoy.html) R package. This conveniently provides an API for obtaining all manner of AFL statistics sourced from multiple databases. This obviously will be of great use for this project.

However, I found it only contained AFL fantasy scores dating back to 2010. After a little bit of time hacking together some scripts to scrape data off [Footywire](https://www.footywire.com/)(one of the main repositories of statistical information) I was able to obtain fantasy data for the 2007 - 2009 seasons. 

In total, I have individual player statistical data spanning 2007 - 2024 to explore.

## Data Insights

There is a considerable amount of available data, not all of which correlate with a players chances of getting Brownlow votes. Let's take a look into the data and see what may be useful to predict a players chances of receiving Brownlow votes. This will help us decide what information to focus on for predicting our models.

For the purposes of creating predictive models, raw numbers are not helpful. Instead, we need to normalise the data in a representative fashion. For example, based on the maximum value obtained within each match. This also has a secondary benefit of dealing with the shortened matches of 2020 due to Covid-19.

## Predictive models

Briefly searching the web, I stumbled upon a few existing models to predict the AFL Brownlow: (i) Ordinal Logistic Regression combined with Monte Carlo simulations [Monte ChaRlo](https://chewthestat.com/monte-charlo-using-data-to-predict-the-brownlow-medal/) (ii) [automated machine learning](https://github.com/betfair-datascientists/predictive-models/blob/master/brownlow/Betfair%20Data%20Scientists'%20Brownlow%20Model.ipynb) (iii) [simple ranking based approach](https://justindatascience.com/predicting-brownlow-votes/) and (iv) a [random forest approach](https://towardsdatascience.com/brownlow-medal-predictor-36586d535226)

Each slightly differs in their predictive model methodology or the volume of data (and features used) and were extremely helpful resources when constructing my own models or giving me ideas.

For now, my likely overly ambitious goal is to create several different predictive models based on a variety of different methodologies.

### Random Forest Classification

The logical go-to first attempt for a Brownlow predictor

### Ordinal Logistic Regression

Inspired entirely by Monte ChaRlo approach

### Simulation Based Inference

No idea if this will work, however, it is a familiar technique from my astrophysics research

## Predictions

In preparation for the upcoming 2024 Brownlow medal, below I provde the predictions for the various models I have considered.

As a summary of the 

## Contact Information

For any questions please contact [Brad Greig](mailto:brad.s.greig@gmail.com).