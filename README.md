# FindMyFGC - Tournament Locator

A specialized gaming tournament locator for the Fighting Game Community (FGC), powered by a Swift backend proxy and a React frontend.

# 🔑 Obtaining API Keys

This app requires two external API keys to function:

### 1. Gemini API (for Geocoding/NLP)

Used to translate queries like "the big apple" or "60601" into GPS coordinates.

- **Where to get:** [Google AI Studio](https://aistudio.google.com/)
- **Instructions:** Sign in, click "Get API key," and create a new key.

### 2. Start.gg API (for Tournament Data)

Used to fetch event details from the world's largest tournament platform.

- **Where to get:** [start.gg Developer Settings](https://start.gg/admin/profile/developer)
- **Instructions:** Create a new "Personal Access Token."

> [!IMPORTANT]
> **Dev vs Production:** We strongly recommend generating separate keys for development and production. This ensures that a compromised dev key doesn't take down your live site and allows for cleaner usage monitoring/billing.

---

## 🛠 Local Development

To run the application locally using Docker:

### 1. Build the Backend Image

Run this command from the **project root** directory:

```bash
docker build -t fgc-backend .
```

### 2. Run the Container

Replace `YOUR_TOKEN` values with your actual API keys.

- `STARTGG_API_KEY`: Found in your [start.gg developer settings](https://start.gg/admin/profile/developer).
- `GEMINI_API_KEY`: Found in [Google AI Studio](https://aistudio.google.com/).

```bash
docker run -p 8080:8080 \
  -e STARTGG_API_KEY=YOUR_STARTGG_TOKEN \
  -e GEMINI_API_KEY=YOUR_GEMINI_TOKEN \
  fgc-backend
```

### 3. Start the Frontend

In a new terminal:

```bash
npm install
npm run dev
```

The frontend is configured via `vite.config.ts` to proxy requests to `http://localhost:8080`.

## 🏗 Directory Structure

- `/frontend`: React components and hooks.
- `/backend`: Swift/Vapor source code.
- `/infra`: Terraform configuration.
- `Dockerfile`: Root build file for the backend.

## 📝 Troubleshooting

- **Error: Unable to find image**: Ensure you ran the `docker build` command successfully first.
- **Port 8080 already in use**: Stop any other local services running on 8080 or change the mapping to `-p 8081:8080`.

## 🧪 Testing

### Frontend Tests (React)

We use **Vitest** for unit and integration testing of our frontend logic.

```bash
# Run tests once
npm test

# Run tests in watch mode
npm run test -- --watch
```

### Backend Tests (Swift)

We use **XCTest** for validating our Swift backend logic.

```bash
cd backend
swift test
```

## 🚀 Cloud Deployment (AWS + HCP Terraform)

This project is configured for a professional, low-cost deployment on AWS using ECS Fargate.

### 1. Prerequisites

- AWS Account
- HCP Terraform Account (connected to your GitHub)
- Start.gg API Key

### 2. Infrastructure Deployment

1.  **HCP Setup**:
    - Create a workspace in HCP Terraform.
    - Connect it to your GitHub repository.
    - Set the `aws_region` and `startgg_api_key` variables in HCP.
2.  **Apply**: Push your changes to the `main` branch. GitHub Actions (or HCP directly) will trigger `terraform apply`.
3.  **Outputs**: Grab the `ecr_repository_url` and `frontend_url` from the Terraform output console.

### 3. CI/CD Workflow (GitHub Actions)

Your GitHub Action should follow these steps:

#### Backend Deployment

```bash
# 1. Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPO_URL>

# 2. Build & Push
cd backend
docker build -t <ECR_REPO_URL>:latest .
docker push <ECR_REPO_URL>:latest

# 3. Refresh ECS
aws ecs update-service --cluster findmyfgc-cluster --service findmyfgc --force-new-deployment
```

#### Frontend Deployment

```bash
# 1. Build React
npm install
VITE_BACKEND_URL=<BACKEND_ALB_URL> npm run build

# 2. Sync to S3
aws s3 sync dist/ s3://<S3_BUCKET_NAME> --delete

# 3. Invalidate CDN
aws cloudfront create-invalidation --distribution-id <CF_DIST_ID> --paths "/*"
```
