help: ## Shows this help
	@echo "$$(grep -h '#\{2\}' $(MAKEFILE_LIST) | sed 's/: #\{2\} /	/' | column -t -s '	')"

tdd: ## Run tests with a watcher
	ptw -- -sx

test: ## Run test suite
	pytest --cov
