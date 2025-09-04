# NYCAD Analytics Dashboard

- Data source: posgres SQL
- Backend: Node.js + Express + Postgres, daily sync job
- Frontend: React + Tailwind CSS
- Orchestration: docker-compose

## Project Structure


```
├── .github/
│   └── workflows/
│       ├── ci-backend.yaml
│       └── ci-frontend.yaml
├── backend/
│   ├── __tests__/
│   │   └── utils.test.js
│   ├── src/
│   │   ├── setup/
│   │   │   ├── routes/
│   │   │   │   ├── drivers.js
│   │   │   │   └── stats.js
│   │   │   ├── services/
│   │   │   │   ├── fetchAndStore.js
│   │   │   │   └── populateTrends.js
│   │   │   ├── utils/
│   │   │   │   └── validation.js
│   │   │   ├── db.js
│   │   │   └── init.sql
│   │   └── server.js
│   ├── .dockerignore
│   ├── .env.example
│   ├── Dockerfile
│   ├── jest.config.js
│   ├── package-lock.json
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── BoroughChart.jsx
│   │   │   └── TrendChart.jsx
│   │   ├── lib/
│   │   │   └── api.js
│   │   ├── pages/
│   │   │   ├── Dashboard.jsx
│   │   │   └── Search.jsx
│   │   ├── App.jsx
│   │   ├── main.jsx
│   │   └── styles.css
│   ├── .dockerignore
│   ├── .env.example 
│   ├── Dockerfile
│   ├── index.html
│   ├── package-lock.json
│   ├── package.json
│   ├── postcss.config.js
│   ├── tailwind.config.js
│   └── vite.config.js
├── .gitignore
├── README.md
├── docker-compose.yml
├── package-lock.json
└── sonar-project.properties
```
## Continuous Integration

This project uses GitHub Actions for CI on both frontend and backend:

- **Frontend CI** ([.github/workflows/ci-frontend.yaml](.github/workflows/ci-frontend.yaml)):  
  Runs on pushes and pull requests to `main` affecting the `frontend/` directory.  
  Steps include dependency installation, secret scanning, SonarQube analysis, and build verification.

- **Backend CI** ([.github/workflows/ci-backend.yaml](.github/workflows/ci-backend.yaml)):  
  Runs on pushes and pull requests to `main` affecting the `backend/` directory.  
  Steps include dependency installation, linting, testing, secret scanning, and SonarQube analysis.


## Backend Setup (Local)

1. Create `backend/.env` from `.env.example` and adjust if needed.
2. Ensure Postgres is running and accessible with the provided credentials.
3. Install deps and start:

```bash
cd backend
npm install
npm run seed # optional: one-time sync
npm run dev  # starts on http://localhost:4000
```

### API Endpoints

- `GET /drivers?borough=Queens&search=smith&page=1&limit=25` — list drivers
- `GET /drivers/:license` — single driver by license
- `GET /stats` — totals and borough breakdown

## Frontend Setup (Local)

```bash
cd frontend
npm install
# Set VITE_API_BASE_URL in .env if backend not on http://localhost:4000
npm run dev  # http://localhost:5173
```

## Run with docker-compose

```bash
docker-compose up --build
```

- Frontend: http://localhost:5173
- Backend: http://localhost:4000
- Postgres: localhost:5432 (user `postgres`, password `postgres`, db `fhv`)

## Notes

- The backend schedules a daily sync (default 3 AM UTC) using `CRON_SCHEDULE` env var.
- You can force a one-time sync by running `npm run seed` in `backend/`.
- Secrets/DB credentials should be managed via environment variables.
