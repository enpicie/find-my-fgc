
# FindMyFGC - Tournament Locator

Find local gaming tournaments on start.gg using a React frontend and a Swift (Vapor) backend proxy.

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

## 💻 Local Setup Guide

### 1. Backend Setup (Swift + Docker)
1.  Navigate to `backend` folder: `cd backend`
2.  Build: `docker build -t fgc-backend .`
3.  Run: `docker run -p 8080:8080 -e STARTGG_API_KEY=YOUR_TOKEN fgc-backend`

### 2. Frontend Setup (React + Vite)
1.  Install: `npm install`
2.  Run: `VITE_API_KEY=your_gemini_key npm run dev`

## 🛠 Project Structure
- `/terraform`: AWS Infrastructure as Code.
- `/backend`: Swift Vapor application (Logic + Proxy).
- `/services`: Frontend API wrappers.
- `/components`: Reusable React UI elements.
- `App.tsx`: Main application state and layout.
