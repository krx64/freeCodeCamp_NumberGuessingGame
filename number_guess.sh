#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

RANDOM_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0
GAMES_PLAYED=0
LOWEST_GUESS=0
GUESS=0

echo -e "Enter your username:"
read NAME

if [[ ! -z $NAME ]]
then
  # Check if user already exists in database
  USER_DATA=$($PSQL "SELECT games_played, lowest_guess FROM users WHERE name='$NAME'::TEXT")
  if [[ -z $USER_DATA ]]
  then
    # User NOT found in database
    echo -e "Welcome, $NAME! It looks like this is your first time here."
  else
    # User found in database
    USER_DATA_WITH_SPACES_INSTEAD_OF_BARS=${USER_DATA//'|'/' '}
    while read GAMES_PLAYED_LOCAL_VAR LOWEST_GUESS_LOCAL_VAR
    do
      GAMES_PLAYED=$GAMES_PLAYED_LOCAL_VAR
      LOWEST_GUESS=$LOWEST_GUESS_LOCAL_VAR
      echo -e "Welcome back, $NAME! You have played $GAMES_PLAYED games, and your best game took $LOWEST_GUESS guesses."
    done <<< "$USER_DATA_WITH_SPACES_INSTEAD_OF_BARS"
    # With pipe (|) global variables would not be updated
    # Therefore input to while loop is with <<< at the end instead of with | at the beginning
    # Global variable values will be needed later when updating the database
  fi

  echo -e "Guess the secret number between 1 and 1000:"
  while [[ $RANDOM_NUMBER -ne $GUESS ]]
  do
    read GUESS
    if [[ ! $GUESS =~ ^[0-9]+$ ]]
    then
      echo -e "That is not an integer, guess again:"  
    else
      ((NUMBER_OF_GUESSES++))
      if [[ $RANDOM_NUMBER -lt $GUESS ]]
      then
        echo -e "It's lower than that, guess again:"
      elif [[ $RANDOM_NUMBER -gt $GUESS ]]
      then
        echo -e "It's higher than that, guess again:"
      fi
    fi
  done
  ((GAMES_PLAYED++))
  #echo -e "\nGames played: $GAMES_PLAYED, Number of guesses in this game: $NUMBER_OF_GUESSES"
  
  # Update database
  if [[ -z $USER_DATA ]]
  then
    # Add new user
    LOWEST_GUESS=$NUMBER_OF_GUESSES
    USER_ADDITION=$($PSQL "INSERT INTO users(name, games_played, lowest_guess) VALUES('$NAME'::TEXT, $GAMES_PLAYED, $LOWEST_GUESS)")
  else
    # Update data of existing user
    if [[ $NUMBER_OF_GUESSES -lt $LOWEST_GUESS ]]
    then
      LOWEST_GUESS=$NUMBER_OF_GUESSES
    fi
    USER_UPDATE=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED, lowest_guess=$LOWEST_GUESS WHERE name='$NAME'::TEXT")
  fi
  echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"
fi
