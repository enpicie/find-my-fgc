
# FindMyFGC Deployment Guide

## 📦 Packaging the Frontend for AWS

To prepare your React app for S3/CloudFront:

1.  **Build the Project**: Use environment variables to point to your AWS backend.
    ```bash
    # Replace with the ALB DNS from terraform outputs
    export VITE_BACKEND_URL="http://findmyfgc-alb-123456789.us-east-1.elb.amazonaws.com"
    export VITE_API_KEY="your-gemini-key"
    
    npm run build
    ```
    This generates a `dist/` folder.

2.  **Upload to S3**:
    ```bash
    aws s3 sync dist/ s3://findmyfgc-frontend-assets --delete
    ```

3.  **Invalidate CloudFront**: Ensure users get the latest code.
    ```bash
    aws cloudfront create-invalidation \
      --distribution-id <YOUR_DIST_ID> \
      --paths "/*"
    ```

---

## 🏗 Infrastructure Deployment (Terraform)

1.  **Initialize**: `terraform init`
2.  **Plan**: `terraform plan -var="startgg_api_key=your_key"`
3.  **Apply**: `terraform apply -var="startgg_api_key=your_key"`

---

## 🍎 Backend Deployment (Swift)

1.  **Auth**: `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_ECR_REPO>`
2.  **Build**: `docker build -t findmyfgc-backend ./backend`
3.  **Tag**: `docker tag findmyfgc-backend:latest <YOUR_ECR_REPO>:latest`
4.  **Push**: `docker push <YOUR_ECR_REPO>:latest`
5.  **Restart**: `aws ecs update-service --cluster findmyfgc-cluster --service findmyfgc-service --force-new-deployment`

## 💰 Expected AWS Costs
*   **ALB**: ~$16-20/month (Fixed cost for the load balancer).
*   **ECS Fargate**: ~$10/month (at 0.25 vCPU / 0.5GB RAM).
*   **S3/CloudFront**: ~$0.50/month (Usage based).
