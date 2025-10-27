#!/bin/bash

API_BASE_URL="http://127.0.0.1"

cd "$(dirname "$0")"

for api_test in ./api_tests/*
do
	ruby $api_test $API_BASE_URL
done
