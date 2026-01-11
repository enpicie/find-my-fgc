# FindMyFGC

## Local Development

1. Create `packages/server/.env` and add `STARTGG_API_KEY`.
2. Create `packages/client/.env` and add `VITE_GOOGLE_MAPS_API_KEY`.
3. From root: `npm install && npm run dev`.

## Deployment Strategy (AWS via Terraform)

Since you are using Terraform and AWS, here is the recommended architecture:

### 1. Frontend (S3 + CloudFront)

- **Terraform Resources:** `aws_s3_bucket`, `aws_cloudfront_distribution`.
- **Advice:** Build the React app (`npm run build`), and use your GitHub Action to sync the `dist/` folder to S3. CloudFront provides the SSL (HTTPS).

### 2. Backend (AWS App Runner)

- **Terraform Resources:** `aws_apprunner_service`.
- **Advice:** App Runner is the best choice for Express APIs. It handles auto-scaling and provides a URL.
- **Alternative:** AWS Lambda + API Gateway. Use the `serverless-http` wrapper in `index.ts` to convert Express to a Lambda handler.

### 3. Secrets Management

- **DO NOT** put API keys in Terraform `.tfvars`.
- **Do:** Use `aws_secretsmanager_secret`.
- Reference the secret ARN in your App Runner environment configuration within Terraform.

### 4. CI/CD (GitHub Actions)

- **Frontend Action:** Build -> Upload to S3 -> Invalidate CloudFront Cache.
- **Backend Action:** Build Docker Image -> Push to ECR -> Update App Runner Service.
