COMPOSE      = docker compose
DEMO         = $(COMPOSE) -f docker-compose.yml -f docker-compose.demo.yml
PROM_IMAGE   = prom/prometheus:v3.15.0
AM_IMAGE     = prom/alertmanager:v0.34.1
PROM_PORT   ?= $(or $(shell grep -s '^PROMETHEUS_PORT=' .env | cut -d= -f2),9090)

.PHONY: up down demo demo-down check reload logs

up:          ## Start the stack
	$(COMPOSE) up -d

down:        ## Stop the stack (data volumes are kept)
	$(COMPOSE) down

demo:        ## Start the stack with sample databases and all exporters
	$(DEMO) up -d

demo-down:   ## Stop the demo and delete its data
	$(DEMO) down -v

check:       ## Validate Prometheus/Alertmanager config and run alert rule tests
	docker run --rm -v "$(PWD)/prometheus:/etc/prometheus:ro" --entrypoint promtool $(PROM_IMAGE) check config /etc/prometheus/prometheus.yml
	docker run --rm -v "$(PWD)/prometheus:/etc/prometheus:ro" -w /etc/prometheus/tests --entrypoint promtool $(PROM_IMAGE) test rules alerts_test.yml
	docker run --rm -v "$(PWD)/alertmanager:/etc/alertmanager:ro" --entrypoint amtool $(AM_IMAGE) check-config /etc/alertmanager/alertmanager.yml

reload:      ## Apply Prometheus config/rule changes without a restart
	curl -fsS -X POST http://localhost:$(PROM_PORT)/-/reload && echo "Prometheus reloaded"

logs:        ## Follow logs of all services
	$(COMPOSE) logs -f --tail=50
