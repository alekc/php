#!/bin/bash
docker build -t test-build .
docker run --rm  -e NEW_RELIC_ENABLED=true -e PHPED_ENABLED=true --name=testing test-build
