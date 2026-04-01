# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data

all: 
	@echo "Creando directorios para volúmenes..."
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@echo "Levantando contenedores..."
	docker compose -f $(COMPOSE_FILE) up -d --build

clean:
	@echo "Deteniendo contenedores..."
	docker compose -f $(COMPOSE_FILE) down

fclean: clean
	@echo "Limpiando todo (Contenedores, imágenes, volúmenes y redes)..."
	docker compose -f $(COMPOSE_FILE) down -v --rmi all
	sudo rm -rf $(DATA_DIR)/mariadb/*
	sudo rm -rf $(DATA_DIR)/wordpress/*

re: fclean all

.PHONY: all clean fclean re