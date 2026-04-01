# ============================================================================== #
#                                 VARIABLES                                      #
# ============================================================================== #

COMPOSE_FILE	= ./srcs/docker-compose.yml
DATA_DIR		= /home/$(USER)/data

# Colors for echos
GREEN			= \033[0;32m
RED				= \033[0;31m
BLUE			= \033[0;34m
YELLOW			= \033[0;33m
RESET			= \033[0m

# ============================================================================== #
#                               MAIN RULES                                       #
# ============================================================================== #

# all: Creates necessary folders and starts everything in the background
all: 
	@echo "$(BLUE)=== Starting Inception project ===$(RESET)"
	@echo "$(GREEN)[+] Creating volume directories in $(DATA_DIR)...$(RESET)"
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@echo "$(GREEN)[+] Building and starting containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) up -d --build
	@echo "$(BLUE)=== Inception is safely up and running! ===$(RESET)"

# clean: Stops containers without removing data or images
clean:
	@echo "$(RED)[-] Stopping Inception infrastructure...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down
	@echo "$(RED)[-] Containers stopped.$(RESET)"

# fclean: Deep clean. Removes containers, images, volumes, and local data
fclean: clean
	@echo "$(RED)[-] Performing deep clean (fclean)...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down -v --rmi all
	@echo "$(RED)[-] Deleting local folder contents (requires sudo)...$(RESET)"
	@sudo rm -rf $(DATA_DIR)/mariadb/*
	@sudo rm -rf $(DATA_DIR)/wordpress/*
	@echo "$(BLUE)=== Full cleanup completed successfully ===$(RESET)"

# re: Restarts the project from scratch
re: fclean all

# ============================================================================== #
#                              EXTRA TOOLS                                       #
# ============================================================================== #

# Useful for pausing the infrastructure without destroying it
stop:
	@echo "$(YELLOW)[~] Pausing containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) stop

# Useful for resuming paused containers
start:
	@echo "$(GREEN)[+] Resuming containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) start

# Shows the status of your containers
status:
	@echo "$(BLUE)=== Inception containers status ===$(RESET)"
	@docker compose -f $(COMPOSE_FILE) ps

# The crown jewel: Real-time logs for debugging
logs:
	@echo "$(YELLOW)[~] Displaying real-time logs (Ctrl+C to exit)...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) logs -f

.PHONY: all clean fclean re stop start status logs
