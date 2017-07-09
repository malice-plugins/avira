REPO=malice-plugins/avira
ORG=malice
NAME=avira
VERSION=$(shell cat VERSION)
AVIRA_KEY?=$(shell cat hbedv.key | base64)

all: build size test avtest gotest

build:
	docker build --build-arg AVIRA_KEY=${AVIRA_KEY} -t $(ORG)/$(NAME):$(VERSION) .

base:
	docker build -f Dockerfile.base -t $(ORG)/$(NAME):base .

dev:
	docker build --build-arg AVIRA_KEY=${AVIRA_KEY} -f Dockerfile.dev -t $(ORG)/$(NAME):$(VERSION) .

size:
	sed -i.bu 's/docker%20image-.*-blue/docker%20image-$(shell docker images --format "{{.Size}}" $(ORG)/$(NAME):$(VERSION)| cut -d' ' -f1)-blue/' README.md

tags:
	docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" $(ORG)/$(NAME)

ssh:
	@docker run --init -it --rm --entrypoint=bash $(ORG)/$(NAME):$(VERSION)

tar:
	docker save $(ORG)/$(NAME):$(VERSION) -o $(NAME).tar

gotest:
	go get
	go test -v

avtest:
	@echo "===> ${NAME} EICAR Test"
	@docker run --init --rm --entrypoint=sh $(ORG)/$(NAME):$(VERSION) -c "/opt/avira/scancl /malware/EICAR" > tests/av.virus || true
	@echo "===> ${NAME} Clean Test"
	@docker run --init --rm --entrypoint=sh $(ORG)/$(NAME):$(VERSION) -c "/opt/avira/scancl /bin/cat" > tests/av.clean || true
	@echo "===> ${NAME} Version"
	@docker run --init --rm --entrypoint=sh $(ORG)/$(NAME):$(VERSION) -c "/opt/avira/scancl --version" > tests/av.version || true

test:
	@echo "===> Starting elasticsearch"
	@docker rm -f elasticsearch || true
	@docker run --init -d --name elasticsearch -p 9200:9200 blacktop/elasticsearch
	@echo "===> ${NAME} --help"
	@sleep 10; docker run --init --rm $(ORG)/$(NAME):$(VERSION)
	@echo "===> ${NAME} EICAR test"
	@docker run --init --rm --link elasticsearch $(ORG)/$(NAME):$(VERSION) -V EICAR | jq . > docs/results.json
	@cat docs/results.json | jq .
	@echo "===> ${NAME} pull MarkDown from elasticsearch results"			
	@http localhost:9200/malice/_search | jq . > docs/elastic.json
	@cat docs/elastic.json | jq -r '.hits.hits[] ._source.plugins.av.${NAME}.markdown' > docs/SAMPLE.md
	@docker rm -f elasticsearch

circle: ci-size
	@sed -i.bu 's/docker%20image-.*-blue/docker%20image-$(shell cat .circleci/SIZE)-blue/' README.md
	@echo "===> Image size is: $(shell cat .circleci/SIZE)"

ci-build:
	@echo "===> Getting CircleCI build number"
	@http https://circleci.com/api/v1.1/project/github/${REPO} | jq '.[0].build_num' > .circleci/build_num

ci-size: ci-build
	@echo "===> Getting image build size from CircleCI"
	@http "$(shell http https://circleci.com/api/v1.1/project/github/${REPO}/$(shell cat .circleci/build_num)/artifacts${CIRCLE_TOKEN} | jq '.[].url')" > .circleci/SIZE

clean:
	docker-clean stop
	docker rmi $(ORG)/$(NAME):$(VERSION)

.PHONY: build dev size tags test gotest clean circle
