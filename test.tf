module "app_service_test" {

    source = "./modules/"
    app_service_plan_name = "plan-dev"
    app_service_name = "mydemowebapp02"
    resource_group_name = "app-service-dev-rg"
    resource_group_location = "eastus"
  
}