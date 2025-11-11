#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ WELCOME TO URBAN SALON ~~~~~\n"
echo -e "Welcome to Urban Salon, how can I help you?\n"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # display services list
  SERVICES_LIST=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")
  echo "$SERVICES_LIST" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  # read selected service id
  read SERVICE_ID_SELECTED

  # validate service
  SERVICE_AVAILABLE=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_SELECTED;")
  if [[ -z $SERVICE_AVAILABLE ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
    return
  fi

  # ask for phone
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # check if phone exists
  CUSTOMER_RECORD=$($PSQL "SELECT customer_id, name FROM customers WHERE phone='$CUSTOMER_PHONE';")

  if [[ -z $CUSTOMER_RECORD ]]
  then
    # new customer
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    INSERT_CUSTOMER=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
  else
    # customer exists, extract name
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE';")
  fi

  # Get customer_id (now guaranteed to exist)
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';")

  # get service name for final output
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED;")

  # ask for time
  echo -e "\nWhat time would you like your $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')?"
  read SERVICE_TIME

  # insert appointment
  INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")

  # Output confirmation (trim whitespace from psql output)
  SERVICE_NAME_PRINT=$(echo $SERVICE_NAME | sed -r 's/^ *| *$//g')
  CUSTOMER_NAME_PRINT=$(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')
  SERVICE_TIME_PRINT=$(echo $SERVICE_TIME | sed -r 's/^ *| *$//g')

  echo -e "\nI have put you down for a $SERVICE_NAME_PRINT at $SERVICE_TIME_PRINT, $CUSTOMER_NAME_PRINT."
}

MAIN_MENU
