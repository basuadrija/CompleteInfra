provider "aws" {
  region = "ap-south-1" # Change as needed
}

# Example: Call EKS module
module "eks" {
  source = "./modules/eks"
  
  # Pass variables defined in modules/eks/variables.tf
  # For example:
   #cluster_name = "my-eks-cluster"
  # node_instance_type = "t3.medium"
}

# Example: Call Nexus module
module "nexus" {
  source = "./modules/nexus"

}

# Example: Call Sonarqube module
module "sonarqube" {
  source = "./modules/sonarqube"

  
}