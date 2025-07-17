# Memoir OCaml Static Site Generator Makefile
# This Makefile provides convenient shortcuts for development tasks

# Configuration
DUNE = dune
BUILD_DIR = _build
SITE_DIR = _site
STATIC_DIR = static
CONTENT_DIR = content
PORT = 8080
HOST = 127.0.0.1

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
MAGENTA = \033[0;35m
CYAN = \033[0;36m
NC = \033[0m # No Color

# Help target - shows available commands
.PHONY: help
help:
	@echo ""
	@echo "$(CYAN)Memoir Static Site Generator$(NC)"
	@echo "$(MAGENTA)=============================$(NC)"
	@echo ""
	@echo "$(YELLOW)Primary Development Commands:$(NC)"
	@echo "  $(GREEN)make generate$(NC)          - Generate the static site"
	@echo "  $(GREEN)make serve$(NC)             - Start development server on http://$(HOST):$(PORT)"
	@echo ""
	@echo "$(YELLOW)Build & Test Commands:$(NC)"
	@echo "  $(GREEN)make build$(NC)            - Build the project"
	@echo "  $(GREEN)make test$(NC)             - Run all tests"
	@echo "  $(GREEN)make test-verbose$(NC)     - Run all tests with verbose output"
	@echo "  $(GREEN)make test-watch$(NC)       - Run tests in watch mode"
	@echo "  $(GREEN)make clean$(NC)            - Clean build artifacts"
	@echo ""
	@echo "$(YELLOW)Utility Commands:$(NC)"
	@echo "  $(GREEN)make fmt$(NC)              - Format OCaml code"
	@echo "  $(GREEN)make watch$(NC)            - Watch files and rebuild automatically"
	@echo ""
	@echo "$(YELLOW)Content Commands:$(NC)"
	@echo "  $(GREEN)make new-post$(NC)         - Create a new blog post"
	@echo "  $(GREEN)make new-page$(NC)         - Create a new page"
	@echo ""
	@echo "$(YELLOW)Debug Commands:$(NC)"
	@echo "  $(GREEN)make info$(NC)             - Show project information and directory status"
	@echo ""

# Primary commands - what you asked for
.PHONY: generate
generate: build
	@echo "$(BLUE)🚀 Generating static site...$(NC)"
	@$(DUNE) exec bin/generator.exe
	@echo "$(GREEN)✅ Site generated successfully in $(SITE_DIR)/$(NC)"
	@echo "$(BLUE)🔍 Running formatter on generated files...$(NC)"
	@$(MAKE) fmt

.PHONY: serve
serve: build
	@echo "$(BLUE)🌐 Starting development server...$(NC)"
	@echo "$(YELLOW)📍 Server will be available at: http://$(HOST):$(PORT)$(NC)"
	@echo "$(MAGENTA)🛑 Press Ctrl+C to stop the server$(NC)"
	@$(DUNE) exec bin/server.exe

# Build commands
.PHONY: build
build:
	@echo "$(BLUE)🔧 Building project...$(NC)"
	@$(DUNE) build
	@echo "$(GREEN)✅ Build completed$(NC)"

# Test commands
.PHONY: test
test: build
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	@$(DUNE) runtest || (echo "$(RED)❌ Some tests failed$(NC)" && exit 1)
	@echo "$(GREEN)✅ All tests passed$(NC)"

.PHONY: test-watch
test-watch:
	@echo "$(BLUE)🔍 Running tests in watch mode...$(NC)"
	@$(DUNE) runtest --watch

.PHONY: test-verbose
test-verbose: build
	@echo "$(BLUE)🧪 Running tests with verbose output...$(NC)"
	@$(DUNE) runtest --verbose

# Clean commands
.PHONY: clean
clean:
	@echo "$(BLUE)🧹 Cleaning build artifacts...$(NC)"
	@$(DUNE) clean
	@echo "$(GREEN)✅ Clean completed$(NC)"


# Development utilities
.PHONY: fmt
fmt:
	@echo "$(BLUE)💅 Formatting OCaml code...$(NC)"
	@$(DUNE) fmt
	@echo "$(GREEN)✅ OCaml code formatted$(NC)"
	@echo "$(BLUE)💅 Formatting CSS files...$(NC)"
	@npx prettier --write --log-level=warn "$(SITE_DIR)/static/css/*.css" || true
	@echo "$(GREEN)✅ CSS formatted$(NC)"
	@echo "$(BLUE)💅 Formatting HTML files...$(NC)"
	@npx prettier --write --log-level=warn "$(SITE_DIR)/**/*.html" || true
	@echo "$(GREEN)✅ HTML formatted$(NC)"
	@echo "$(BLUE)💅 Formatting JavaScript files...$(NC)"
	@npx prettier --write --log-level=warn "$(SITE_DIR)/static/js/*.js" || true
	@echo "$(GREEN)✅ JavaScript formatted$(NC)"

.PHONY: dev
dev: build
	@echo "$(BLUE)🚀 Starting development mode...$(NC)"
	@echo "$(YELLOW)📍 Server: http://localhost:3000 | Auto-reload enabled$(NC)"
	@echo "$(YELLOW)📍 Watching: content/ and static/ for changes$(NC)"
	@echo "$(MAGENTA)🛑 Press Ctrl+C to stop$(NC)"
	@(browser-sync start --server "_site" --files "_site/**/*" --port 3000 --no-open --no-notify &) && \
	npx nodemon --watch content --watch static -e md,css,js --exec "make generate"

.PHONY: watch  
watch: dev


# Content creation helpers
.PHONY: new-post
new-post:
	@read -p "Enter blog post title: " title; \
	slug=$$(echo "$$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$$//g'); \
	file="$(CONTENT_DIR)/blog/$$slug.md"; \
	date=$$(date +%Y-%m-%d); \
	echo "$(BLUE)📝 Creating new blog post: $$file$(NC)"; \
	mkdir -p $$(dirname "$$file"); \
	echo "---" > "$$file"; \
	echo "title: \"$$title\"" >> "$$file"; \
	echo "date: $$date" >> "$$file"; \
	echo "tags: []" >> "$$file"; \
	echo "draft: true" >> "$$file"; \
	echo "description: \"\"" >> "$$file"; \
	echo "---" >> "$$file"; \
	echo "" >> "$$file"; \
	echo "# $$title" >> "$$file"; \
	echo "" >> "$$file"; \
	echo "Your content here..." >> "$$file"; \
	echo "$(GREEN)✅ Created: $$file$(NC)"

.PHONY: new-page
new-page:
	@read -p "Enter page title: " title; \
	slug=$$(echo "$$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$$//g'); \
	file="$(CONTENT_DIR)/pages/$$slug.md"; \
	echo "$(BLUE)📄 Creating new page: $$file$(NC)"; \
	mkdir -p $$(dirname "$$file"); \
	echo "---" > "$$file"; \
	echo "title: \"$$title\"" >> "$$file"; \
	echo "layout: \"page\"" >> "$$file"; \
	echo "description: \"\"" >> "$$file"; \
	echo "---" >> "$$file"; \
	echo "" >> "$$file"; \
	echo "# $$title" >> "$$file"; \
	echo "" >> "$$file"; \
	echo "Your content here..." >> "$$file"; \
	echo "$(GREEN)✅ Created: $$file$(NC)"

# Info commands
.PHONY: info
info:
	@echo "$(CYAN)📋 Project Information$(NC)"
	@echo "Build tool: $(DUNE)"
	@echo "Build directory: $(BUILD_DIR)"
	@echo "Site directory: $(SITE_DIR)"
	@echo "Content directory: $(CONTENT_DIR)"
	@echo "OCaml server: http://$(HOST):$(PORT)"
	@echo "BrowserSync dev server: http://localhost:3000"
	@echo ""
	@echo "$(BLUE)📊 Site size information:$(NC)"
	@if [ -d "$(SITE_DIR)" ]; then \
		echo "Total site size: $$(du -sh $(SITE_DIR) | cut -f1)"; \
		echo "Breakdown:"; \
		du -h --max-depth=1 $(SITE_DIR) | sort -hr; \
	else \
		echo "$(YELLOW)⚠️ Site directory doesn't exist. Run 'make generate' first.$(NC)"; \
	fi


# Default target
.DEFAULT_GOAL := help

# Make sure these directories exist
$(SITE_DIR):
	@mkdir -p $(SITE_DIR)

$(CONTENT_DIR):
	@mkdir -p $(CONTENT_DIR)/pages $(CONTENT_DIR)/blog

# Phony targets to avoid conflicts with files
.PHONY: help generate serve build test test-watch test-verbose clean fmt watch new-post new-page info