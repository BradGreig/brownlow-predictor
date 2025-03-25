library("MASS")
library(data.table)
library(magrittr)
library(dplyr)
library(caret)
library(feather)

# Read in the relevant historical information
# Data has been converted to csv for usage in R
historical_data <- read.csv("historical_data_2007_2024.csv")
class(historical_data)

# Assign the first and last year of data to be used as a training set
first_year <- 2007
final_year <- 2023

# Create a list of summary information
summary_information = matrix(6)

# Set the prediction year for the AFL Brownlow
predict_year <- 2024
print(sprintf("Predicting year %s",predict_year))

# Create a string of all the years to be used for the training set
# Done in this way for instances when prediction year is not the final year
years_for_training <- paste(first_year:final_year,collapse='|')
print(years_for_training)
  
# Obtaining the training data set from our selected years of training data
training_set<-historical_data[substr(historical_data$MatchId,1,4) %like% years_for_training, ]

# Obtain the relevant statistical data for the season we intend to predict
prediction_set<-historical_data[substr(historical_data$MatchId,1,4) %like% predict_year, ]
  
# Create the Ordinal Logistic Regression model, assigning the relevant statistical information
# to be used in the model
brownlow_predictor <- polr(as.factor(BrownlowVotes) ~ NormDisposals + 
                               NormGoals +
                               NormHitouts + 
                               NormTackles + 
                               NormMarks +
                               NormContestedMarks + 
                               NormInside50s + 
                               NormClearances +
                               NormContestedPossessions + 
                               NormGoalAssists +
                               NormDreamTeamPoints + 
                               NormSupercoach +
                               CoachesVotes + 
                               Margin_y +
                               Winner, data = training_set,
                             Hess=TRUE, method = c("logistic"))

# Obtain the prediction probabilities for the current AFL season based on the OLR model
predicted_probs <- as.data.frame(predict(brownlow_predictor, 
                                           newdata = prediction_set, type = "probs"))
  
# Convert these prediction probabilities into a matrix
predictions_probability_matrix  <- data.frame(matrix(unlist(predicted_probs), 
                                                       nrow = nrow(validation_set)))
  
# Assign column names to the prediction probability matrix (zero, one, two and three votes)
colnames(predictions_probability_matrix) <- c("Zero", "One", "Two", "Three")

# Add these Brownlow probabilities to the original dataset for the current AFL season
brownlow_predictions  <- cbind.data.frame(prediction_set, predictions_probability_matrix)

# Create a new entry for our season prediction containing our expected votes (calculated from 
# the sum of the vote amount * probability)
brownlow_predictions$ExpectedVotes <- 1*brownlow_predictions$One + 
    2*brownlow_predictions$Two + 3*brownlow_predictions$Three
  
# Create a new data frame called matchday votes, which assigns 3-2-1 votes to the players with 
# the three highest expected votes for each AFL match in the season
matchday_votes <- brownlow_predictions %>%
    group_by(MatchId) %>% # Ensuring I am selecting by each match individually
    top_n(3, ExpectedVotes) %>% # I want only the top 3 expected votes
    # Predicted votes are assigned 3-2-1 based on expected votes
    mutate(PredictedVotes = order(order(ExpectedVotes, PlayerName, decreasing=FALSE))) %>% 
    select(MatchId, PlayerName, Team, PredictedVotes, ExpectedVotes) %>% # Data to retain for this dataframe
    arrange(MatchId, desc(PredictedVotes)) # Order by predicted votes (3-2-1)

brownlow_votes_validation <- prediction_set %>% 
    select(MatchId, PlayerName, Team, BrownlowVotes) 
  
# Add the true Brownlow votes for the AFL season to the predicted votes
# Full join to account for the different predicted players compared to the true votes being awarded
matchday_votes <- full_join(matchday_votes,
                              brownlow_votes_validation) %>% 
                              arrange(MatchId, desc(PredictedVotes))

# Replace all N/A entries with zeros
matchday_votes$PredictedVotes <- replace(matchday_votes$PredictedVotes, 
                                           is.na(matchday_votes$PredictedVotes), 
                                           0)

# Change datatype for Predicted and Brownlow votes
matchday_votes$PredictedVotes <- as.factor(matchday_votes$PredictedVotes)
matchday_votes$BrownlowVotes <- as.factor(matchday_votes$BrownlowVotes)
  
# Calculate the confusion matrix (determines the accuracy of our classification model)
# (i.e. number of times we correctly predict 3 votes)
confusion_matrix <- confusionMatrix(matchday_votes$PredictedVotes, matchday_votes$BrownlowVotes)

# Calculate the Brownlow tally (summing over individual players to determine their totals)
# This is for 3-2-1 voting
vote_tally <- matchday_votes %>%
    group_by(PlayerName, Team) %>% # Select individual players (use team information to differentiate players with similar names)
    # Sum the number of 3 votes and multiply by 3, same for two and one
    summarise(PredictedVotes = 3 * sum(PredictedVotes == 3) +
                2 * sum(PredictedVotes == 2) +
                1 * sum(PredictedVotes == 1), .groups = 'drop') %>%
    arrange(desc(PredictedVotes)) # Sort the information
  
# Calculate the Brownlow tally (summing over individual players to determine their totals)
# This is for expected vote information
vote_tally_expected <- brownlow_predictions %>%
    group_by(PlayerName, Team) %>% # Select individual players (use team information to differentiate players with similar names)
    summarise(ExpectedVotes = sum(ExpectedVotes), .groups = 'drop') %>%
    arrange(desc(ExpectedVotes))
  
# Outer join the two different tallies for storage in a single dataframe
# that can be output using feature and read in by Python for comparison
# with the other models
full_vote_info <- full_join(vote_tally,
                              vote_tally_expected) %>% 
    arrange(PredictedVotes, desc(PredictedVotes))

# Write the dataframe to a file readable by Python (using the feather package)
write_feather(full_vote_info,sprintf("BrownlowPredictions_%s.feather",predict_year))
  
summary_information[1] <- predict_year
summary_information[2] <- confusion_matrix$table[2,2] # Number of one vote games
summary_information[3] <- confusion_matrix$table[3,3] # Number of two vote games
summary_information[4] <- confusion_matrix$table[4,4] # Number of three vote games
summary_information[5] <- sum(confusion_matrix$table[2:3,2:3]) # Number of times a player was given either 1 or 2 votes
summary_information[6] <- sum(confusion_matrix$table[2:4,2:4]) # Number of times a player was given either 1, 2 or 3 votes

# Output the summary information
write.csv(summary_information, "summary_information.csv")