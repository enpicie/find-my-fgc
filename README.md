# FindMyFGC

A specialized gaming tournament locator for the Fighting Game Community (FGC), powered by a Swift backend proxy and a React frontend.

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

## 📦 Packaging the Frontend for AWS
1. Build the project: `npm run build`
2. Sync with S3: `aws s3 sync dist/ s3://your-bucket-name --delete`

## 🏗 Infrastructure Deployment (Terraform)
1. Initialize: `terraform init`
2. Apply: `terraform apply`

## 🍎 Backend Deployment (Swift)
1. Build & Push Docker image to ECR.
2. Force new deployment on ECS.