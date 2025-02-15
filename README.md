## Terraform Remote State Backend using S3 and DynamoDB

### Why Do We Need Remote State?  
When working in a team or managing large infrastructure, storing the Terraform state file (`terraform.tfstate`) **locally** is risky because:  
1. **Collaboration Issues** – Other team members won’t have access to the latest state.  
2. **Accidental Deletion** – If the local machine is lost, so is the state file.  
3. **Concurrency Problems** – Multiple people running `terraform apply` can cause conflicts.  

#### Scenario:

When multiple DevOps engineers are working on the same Terraform project, and the state file is shared (e.g., through a version control system like GitHub), there are potential issues:

- If one engineer updates the infrastructure, they must push both the updated code and the updated state file to keep everything in sync.
- If an engineer forgets to push their updated state file, other engineers will be working with an outdated state file. This mismatch between the state file and the actual infrastructure can lead to errors, inconsistencies, or unexpected behavior during subsequent Terraform operations.

### How S3 & DynamoDB Help  
To solve these issues, we store Terraform state **remotely** and use **locking**:  

1. **S3 (Remote State Storage)**  
   - Stores `terraform.tfstate` in an **Amazon S3 bucket**.  
   - Ensures all team members use the same, up-to-date state.  

2. **DynamoDB (State Locking)**  
   - Prevents **simultaneous updates** to the state.  
   - Avoids race conditions where multiple people modify infrastructure at the same time.  
   - Uses a **lock table** in DynamoDB to ensure only one Terraform process runs at a time.  

### Example Terraform Backend Configuration  
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### How It Works  
1. Terraform reads the state from **S3**.  
2. It checks **DynamoDB** for any active locks before making changes.  
3. If no one else is running Terraform, it **locks** the state file.  
4. Once changes are applied, the lock is **released**.  

### Steps

#### 1. Create an S3 Bucket for Storing Terraform State
```hcl
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.s3_bucket_name
}
```
- Creates an **S3 bucket** with the name provided via the variable `var.s3_bucket_name`.  
- This bucket will **store the Terraform state file** to enable remote state management.



#### 2. Enable Versioning for State File Recovery
```hcl
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
```
- Enables **versioning** for the S3 bucket.  
- If the state file is accidentally deleted or modified, you can **restore a previous version**.


#### 3. Encrypt the State File at Rest
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```
- Enables **AES256 server-side encryption** to secure the state file.  
- Ensures that the state file stored in S3 is **encrypted at rest**.


#### 4. Create a DynamoDB Table for State Locking
```hcl
resource "aws_dynamodb_table" "statelock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```
- Creates a **DynamoDB table** to manage **Terraform state locking**.
- The `hash_key` is `"LockID"`, which will store **unique lock identifiers** to prevent simultaneous Terraform runs.
- **PAY_PER_REQUEST** billing mode ensures **cost-efficiency**, charging only for actual usage.


### Next Steps
1. **Apply this module in `main.tf`**  
```hcl
module "backend" {
  source = "./modules/backend"

  s3_bucket_name = var.s3_bucket_name
  dynamodb_table_name = var.dynamodb_table_name
}
```

2. `terraform init`

3. `terraform plan`

4. `terraform apply`

5. **Now the resources are created**

![Image](https://github.com/user-attachments/assets/d5056745-c2f0-4f0a-80c2-a765ce1729a3)

![Image](https://github.com/user-attachments/assets/ede4806a-554b-4c5f-9cd3-fd10ac89b843)

6. **Now Create `backend.tf`**
```
terraform {
  backend "s3" {
    bucket         = "terraform-state-file-abc.d6vs"
    key            = "globals/terraform-state-file/terraform.tfstate" 
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}
```

7. **Comment or remove code from `main.tf` because it will create duplicate resources** 

3. `terraform init`

![Image](https://github.com/user-attachments/assets/ab9d5e5f-57e7-4c7f-a2ac-90fcd13a62e5)

4. `terraform plan`

5. `terraform apply`

6. If you see the `terraform.tfstate` file becomes empty i.e. it has migrated to aws s3

![Image](https://github.com/user-attachments/assets/e5a232a0-7a5b-477b-aabe-c09b1177583a)

![Image](https://github.com/user-attachments/assets/2a0a504f-0b14-472c-a544-babaeacf4de1)
