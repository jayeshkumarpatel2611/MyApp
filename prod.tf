module "app_service_prod" {
  
  source = "./modules/"

  app_service_plan_name = "plan-prod"
  app_service_name = "myprodwebapp02"
  resource_group_name = "app-service-prod-rg"
  resource_group_location = "eastus"
}