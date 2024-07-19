## Init app
- docker compose exec app go mod init app
- docker compose exec app go mod tidy
- docker compose exec app go mod vendor

## Build app
- docker compose exec app go build

## Start app
- docker compose exec app go run main.go

## Generate fixtures
- docker compose exec app go run load.go

## Lancer les tests
- cd app/tests
- go test
