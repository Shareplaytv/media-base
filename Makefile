.PHONY: ecr
ecr:
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

.PHONY: deploy
deploy:
	aws cloudformation deploy \
		--stack-name media-base-public \
		--template-file pipeline.yml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			RepositoryId=wavey-ai/media-base \
			CodeStarConnectionArn=$(CODESTAR_CONNECTION_ARN) \
			BranchName=$(BRANCH_NAME)

.PHONY: push
push:
		docker build -t ${ECR_REPO}:latest -t ${ECR_REPO}:${REV} . && \
		docker push -a ${ECR_REPO}
