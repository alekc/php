#!/bin/bash
docker build -t test-build .
docker run --rm  -d -e NEW_RELIC_ENABLED=true -e PHPED_ENABLED=true --name=testing test-build

#docker tag php-cratercraft-adv registry.55px.xyz/php-cratercraft
#docker push registry.55px.xyz/php-cratercraft