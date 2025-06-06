#!/bin/bash

set_env() {
  echo $1: $2;
  export $1=$2;
}

echo "--- Setting Environment ---"
set_env POSTGRES_USERNAME "<YOUR-USERNAME>"
set_env POSTGRES_PASSWORD "<YOUR-PASSWORD>"
