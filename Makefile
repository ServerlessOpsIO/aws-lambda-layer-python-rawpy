ENV ?= ${USER}
STACKNAME = $(shell basename ${CURDIR})-$(ENV)
AWS_REGION ?= $(shell aws configure get region)

check_profile:
	# Make sure we have a user-scoped credentials profile set. We don't want to be accidentally using the default profile
	@aws configure --profile ${AWS_PROFILE} list 1>/dev/null 2>/dev/null || (echo '\nMissing AWS Credentials Profile called '${AWS_PROFILE}'. Run `aws configure --profile ${AWS_PROFILE}` to create a profile called '${AWS_PROFILE}' with creds to your personal AWS Account'; exit 1)

build:
	$(info Building application)
	sam build --use-container

validate:
	$(info linting SAM template)
	$(info linting CloudFormation)
	@cfn-lint template.yaml
	$(info validating SAM template)
	@sam validate

deploy: build validate
	$(info Deploying to personal development stack)
	sam deploy --stack-name $(STACKNAME) --region ${AWS_REGION} --resolve-s3 --parameter-overrides ServiceEnv=$(ENV)

describe:
	$(info Describing stack)
	@aws cloudformation describe-stacks --stack-name $(STACKNAME) --output table --query 'Stacks[0]'

outputs:
	$(info Displaying stack outputs)
	@aws cloudformation describe-stacks --stack-name $(STACKNAME) --output table --query 'Stacks[0].Outputs'

parameters:
	$(info Displaying stack parameters)
	@aws cloudformation describe-stacks --stack-name $(STACKNAME) --output table --query 'Stacks[0].Parameters'

delete:
	$(info Delete stack)
	@aws cloudformation delete-stack --stack-name $(STACKNAME)

clean:
	$(info cleaning project)
	# remove sam cache
	rm -rf .aws-sam
