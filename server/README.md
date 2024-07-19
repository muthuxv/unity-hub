## Init app
- docker compose exec app go mod init app
- docker compose exec app go mod tidy
- docker compose exec app go mod vendor

## Build app
- docker compose exec app go build

## Start app
- docker compose exec app go run main.go

## Lancer les tests
- cd app/tests
- go test

## Exemple de configuration pour lancement sur poste de travail local

DB_HOST=db
DB_USER=user
DB_PASS=!MuthuTheBest2024!
DB_NAME=app
DB_PORT=5432
JWT_KEY=Muthux_le_boss_Du_75
SMTP_HOST=sandbox.smtp.mailtrap.io
SMTP_PORT=2525
SMTP_USER=4ea7ec0a7eeeb0
SMTP_PASSWORD=e7e19c0f2839c7
DOMAIN=http://195.35.29.110:8080/
CLIENT_ID_GITHUB_AUTH=
CLIENT_SECRET_GITHUB_AUTH=
  
