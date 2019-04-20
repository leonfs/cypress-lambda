pre:
	npm i

build:
	cd lamdba && \
		docker build . -t cypress-lambda

test:
	docker run --rm -v "$$PWD":/var/task:ro lambci/lambda:nodejs8.10

deploy:
	cd lambda && \
		./deps.sh
	terraform init
	terraform apply --auto-approve